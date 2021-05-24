# frozen_string_literal: true

module Planter
  ##
  # The class your seeder files should inherit from.
  class Seeder
    ##
    # The allowed seeding methods.
    #
    # @return [Array]
    SEEDING_METHODS = %i[csv data_array].freeze

    ##
    # Array of hashes used to create records. Your class must set this
    # attribute when using +data_hash+ seeding method, although it's probably
    # more likely that you'll want to define a method that returns a new set of
    # data each time (via +Faker+, +Array#sample+, etc.). When using
    # +csv+, +data+ will be set to the data within the csv. You can
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
    # @kwarg [Integer] number_of_records
    #
    # @kwarg [String] model
    #
    # @kwarg [String] parent_model
    #
    # @kwarg [Symbol, String] association
    #
    # @kwarg [Symbol, String] csv_name
    #
    # @example
    #   require 'planter'
    #   class UsersSeeder < Planter::Seeder
    #     seeding_method :csv,
    #       number_of_records: 2,
    #       model: 'User'
    #       parent_model: 'Person',
    #       association: :users,
    #       csv_name: :awesome_users
    #   end
    def self.seeding_method(
      method,
      number_of_records: 1,
      model: to_s.delete_suffix('Seeder').singularize,
      parent_model: nil,
      association: nil,
      csv_name: nil
    )
      if !SEEDING_METHODS.include?(method.intern)
        raise ArgumentError, "Method must be one of #{SEEDING_METHODS.join(', ')}"
      elsif association && !parent_model
        raise ArgumentError, "Must specify :parent_model with :association"
      end

      @seeding_method = method
      @number_of_records = number_of_records
      @model = model
      @parent_model = parent_model
      @association = @parent_model && (association || determine_association)
      @csv_file = determine_csv_filename(csv_name) if @seeding_method == :csv
    end

    def self.determine_association # :nodoc:
      associations =
        @parent_model.constantize.reflect_on_all_associations.map(&:name)
      table = to_s.delete_suffix('Seeder').underscore.split('/').last

      [table, table.singularize].map(&:intern).each do |t|
        return t if associations.include?(t)
      end

      raise ArgumentError, "Couldn't determine association name"
    end
    private_class_method :determine_association

    def self.determine_csv_filename(csv_name) # :nodoc:
      file = (
        csv_name || "#{to_s.delete_suffix('Seeder').underscore}"
      ).to_s + '.csv'
      [file, "#{file}.erb"].each do |f|
        fname = Rails.root.join(Planter.config.csv_files_directory, f).to_s
        return fname if File.file?(fname)
      end

      raise ArgumentError, "Couldn't find csv for #{@model}"
    end
    private_class_method :determine_csv_filename

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
      when :csv
        contents = File.read(csv_file)
        if csv_file.end_with?('.erb')
          contents = ERB.new(contents, trim_mode: '<>').result(binding)
        end

        @data ||= ::CSV.parse(contents, headers: true).map(&:to_hash)
      when :data_array
        raise "Must define '@data'" if public_send(:data).nil?
      else
        raise("Must set 'seeding_method'")
      end
    end
  end
end
