# frozen_string_literal: true

module Planter
  ##
  # The class your seeder files should inherit from.
  class Seeder
    ##
    # The allowed seeding methods.
    #
    # @return [Array]
    SEEDING_METHODS = %i[standard_csv data_array].freeze

    ##
    # Array of hashes used to create records. Your class must set this
    # attribute when using +data_hash+ seeding method, although it's probably
    # more likely that you'll want to define a method that returns a new set of
    # data each time (via +Faker+, +Array#sample+, etc.). When using
    # +standard_csv+, +data+ will be set to the data within the csv. You can
    # override this.
    #
    # @return [Array]
    attr_reader :data

    ##
    # If your class is going to use the inherited +seed+ method, you must tell
    # it which +seeding_method+ to use. The argument to this method must be
    # included in the +SEEDING_METHODS+ array.
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
      if !SEEDING_METHODS.include?(method.intern)
        raise ArgumentError, "Method must be one of #{SEEDING_METHODS.join(', ')}"
      elsif options[:association] && !options[:parent_model]
        raise ArgumentError, "Must specify :parent_model with :association"
      end

      @seeding_method = method
      @number_of_records = options.fetch(:number_of_records, 1)
      @model = options.fetch(:model, to_s.delete_suffix('Seeder').singularize)
      @parent_model = options[:parent_model]
      @association = @parent_model && options.fetch(:association) do
        determine_association(options)
      end
      return unless @seeding_method == :standard_csv

      @csv_file = options.fetch(:csv_file, Rails.root.join(
        Planter.config.csv_files_directory,
        "#{to_s.delete_suffix('Seeder').underscore}.csv"
      ).to_s)
    end

    def self.determine_association(options) # :nodoc:
      associations =
        @parent_model.constantize.reflect_on_all_associations.map(&:name)
      table = to_s.delete_suffix('Seeder').underscore.split('/').last

      [table, table.singularize].map(&:intern).each do |t|
        return t if associations.include?(t)
      end

      raise ArgumentError, 'Could not determine association name'
    end
    private_class_method :determine_association

    ##
    # The default seed method. To use this method, your class must provide a
    # valid +seeding_method+, and not implement its own +seed+ method.
    def seed
      validate_attributes

      parent_model ? create_records_from_parent : create_records
    end

    protected

    ##
    # The seeding method specified.
    #
    # @return [Symbol]
    def seeding_method
      @seeding_method ||= self.class.instance_variable_get('@seeding_method')
    end

    ##
    # The model for the table being seeded. If the model name you need is
    # different, change via +seeding_method+.
    #
    # @return [String]
    def model
      @model ||= self.class.instance_variable_get('@model')
    end

    ##
    # The model of the parent. When provided with +association+, records in the
    # +data+ array, will be created for each record in the parent table. Your
    # class must set this attribute via +seeding_method+.
    #
    # @return [String]
    def parent_model
      @parent_model ||= self.class.instance_variable_get('@parent_model')
    end

    ##
    # When using +parent_model+, the association name. Your class can set this
    # attribute via +seeding_method+.
    #
    # @return [Symbol]
    def association
      @association ||= self.class.instance_variable_get('@association')
    end

    ##
    # The number of records to create from each record in the +data+ array. If
    # nil, defaults to 1, but you can override this in your class via
    # +seeding_method+.
    #
    # @return [Integer]
    def number_of_records
      @number_of_records ||=
        self.class.instance_variable_get('@number_of_records')
    end

    ##
    # The csv file corresponding to the model.
    #
    # @return [String]
    def csv_file
      @csv_file ||= self.class.instance_variable_get('@csv_file')
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
    def create_records_from_parent
      parent_model.constantize.all.each do |assoc_rec|
        number_of_records.times do
          data.each { |rec| send(create_method, assoc_rec, association, rec) }
        end
      end
    end

    private

    def create_method
      parent_model.constantize.reflect_on_association(
        association
      ).macro.to_s.include?('many') ? :create_has_many : :create_has_one
    end

    def create_has_many(assoc_rec, association, rec)
      assoc_rec.public_send(association).where(rec).first_or_create!
    end

    def create_has_one(assoc_rec, association, rec)
      assoc_rec.public_send("create_#{association}", rec)
    end

    def validate_attributes # :nodoc:
      case seeding_method.intern
      when :standard_csv
        raise "#{csv_file} does not exist" unless ::File.file?(csv_file)

        @data ||= ::CSV.table(csv_file).map(&:to_hash)
      when :data_array
        raise "Must define '@data'" if public_send(:data).nil?
      else
        raise("Must set 'seeding_method'")
      end
    end
  end
end
