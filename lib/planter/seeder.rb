module Planter
  class Seeder
    ##
    # If your class is going to use the inherited +seed+ method, you must tell it
    # which +seeding_method+ to use. The argument to this method must be included
    # in the +SEEDING_METHODS+ array.
    #
    # @param [Symbol] seeding_method
    #
    # @param [Hash] options
    #
    # @example
    #   require 'planter'
    #   class UsersSeeder < Planter::Seeder
    #     seeding_method :data_array,
    #       model: 'User'
    #       parent_model: 'Person',
    #       association: :users,
    #       number_of_records: 2
    #   end
    def self.seeding_method(method, **options)
      if !SEEDING_METHODS.include?(method.to_sym)
        raise ArgumentError, "Method must be one of #{SEEDING_METHODS.join(', ')}"
      elsif options[:association] && !options[:parent_model]
        raise ArgumentError, "Must specify 'parent_model' with 'association'"
      end

      @seeding_method = method
      @number_of_records = options.fetch(:number_of_records, 1)
      @model = options.fetch(:model, to_s.delete_suffix('Seeder').singularize)
      @parent_model = options[:parent_model]
      @association = options.fetch(
        :association,
        @parent_model && to_s.delete_suffix('Seeder').underscore.to_sym
      )
      return unless @seeding_method == :standard_csv

      @csv_file = options.fetch(
        :csv_file,
        File.join(
          seed_files_directory,
          "#{to_s.delete_suffix('Seeder').underscore}.csv"
        )
      )
    end

    ##
    # The default seed method. To use this method, your class must provide a
    # valid seeding_method, and not implement its own +seed+ method.
    def seed
      validate_attributes

      parent_model ? create_child_records : create_records
    end

    protected

    ##
    # The seeding method specified.
    #
    # @return [Symbol]
    def seeding_method
      @seeding_method ||= config.seeding_method
    end

    ##
    # The model for the table being seeded. If the model name you need is
    # different, change via +seeding_method+.
    #
    # @return [String]
    def model
      @model ||= config.model
    end

    ##
    # The model of the parent. When provided with +association+, records in the
    # +data+ array, will be created for each record in the parent table. Your
    # class must set this attribute via +seeding_method+.
    #
    # @return [String]
    def parent_model
      @parent_model ||= config.parent_model
    end

    ##
    # When using +parent_model+, the association name. Your class must set this
    # attribute via +seeding_method+.
    #
    # @return [Symbol]
    def association
      @association ||= config.association
    end

    ##
    # The number of records to create from each record in the +data+ array. If
    # nil, defaults to 1, but you can override this in your class via
    # +seeding_method+.
    #
    # @return [Integer]
    def number_of_records
      @number_of_records ||= config.number_of_records
    end

    ##
    # The csv file corresponding to the model.
    #
    # @return [String]
    def csv_file
      @csv_file ||= config.csv_file
    end

    ##
    # Creates records from the +data+ attribute.
    def create_records
      data.each do |rec|
        number_of_records.times do
          model.constantize.where(
            rec.transform_values { |value| value == 'NULL' ? nil : value }
          ).first_or_create!
        end
      end
    end

    ##
    # Create records from the +data+ attribute for each record in the
    # +parent_table+, via the specified +association+.
    def create_child_records
      parent_model.constantize.all.each do |associated_record|
        number_of_records.times do
          data.each do |rec|
            associated_record.public_send(association).where(rec).first_or_create!
          end
        end
      end
    end

    private

    def config # :nodoc:
      @config ||= self.class.config
    end

    def validate_attributes # :nodoc:
      case seeding_method.to_sym
      when :standard_csv
        raise "#{csv_file} does not exist" unless File.file?(csv_file)

        @data ||= ::CSV.table(csv_file).map(&:to_hash)
      when :data_array
        raise "Must define '@data'" if public_send(:data).nil?
      else
        raise("Must set 'seeding_method'")
      end
    end
  end
end
