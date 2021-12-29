# frozen_string_literal: true

module Planter
  ##
  # Class that seeders should inherit from. Seeders should be in +db/seeds+,
  # and named +TABLE_seeder.rb+, where +TABLE+ is the name of the table being
  # seeded (I.E. +users_seeder.rb+). If your seeder is named differently than
  # the table, you'll need to specify the table with the +model+ option. The
  # seeder's class name should be the same as the file name, but camelized. So,
  # +UsersSeeder+. The directory where the seeder files are located can be
  # changed via an initializer.
  #
  # The most basic way to seed is to have a CSV file with the same name as the
  # table in +db/seed_files/+. So, +users.csv+. This CSV should have the
  # table's column names as header. To seed using this method, your class
  # should look like the following. Note that +:csv_name+ and +:model+ are only
  # required if your seeder or csv are named differently than the table being
  # seeded. The directory where the seed files are kept can be changed via an
  # initializer.
  #   # db/seeds/users_seeder.rb
  #   require 'planter'
  #   class UsersSeeder < Planter::Seeder
  #     seeding_method :csv, csv_name: :users, model: 'User'
  #   end
  #
  # Another way to seed is to create records from a data array. To do this,
  # your class must implement a +data+ attribute or method, which is an array
  # of hashes. Note that this class already provides the +attr_reader+ for this
  # attribute, so the most you have to do is create instance variables in your
  # constructor. If if you want your data to be different for each new record
  # (via Faker, +Array#sample+, etc.), you'll probably want to supply a method
  # called data that returns an array of new data each time.
  #   require 'planter'
  #   class UsersSeeder < Planter::Seeder
  #     seeding_method :data_array
  #     def data
  #       [{foo: 'bar', baz: 'bar'}]
  #     end
  #   end
  #
  # In both of the above methods, you can specify a +parent+ association, which
  # is the +belongs_to+ association name in your model, which, when specified,
  # records will be created for each record in the parent table. For example,
  # if we're seeding the users table, and the model is +User+, which belongs to
  # +Person+, then doing the following will create a user record for each
  # record in the Person table. Note that nothing is automatically done to
  # prevent any validation errors; you must do this on your own, mostly likely
  # using +Faker+ or a similar library.
  #   require 'planter'
  #   class UsersSeeder < Planter::Seeder
  #     seeding_method :data_array, parent: :person
  #     def data
  #       [{foo: 'bar', baz: 'bar'}]
  #     end
  #   end
  #
  # You can also set +number_of_records+ to determine how many times each
  # record in the +data+ array will get created. The default is 1. Note that if
  # this attribute is set alongside +parent+, +number_of_records+ will be how
  # many records will be created for each record in the parent table.
  #   require 'planter'
  #   class UsersSeeder < Planter::Seeder
  #     seeding_method :data_array, number_of_records: 5
  #     def data
  #       [{foo: 'bar', baz: 'bar'}]
  #     end
  #   end
  #
  # By default, all fields are used to look up the record. If it already
  # exists, it is not re-created. If you have specific fields that a record
  # should be looked-up by, you can pass the +unique_columns+ option. This will
  # attempt to look up the record by those fields only, and if one doesn't
  # exist, one will be created with the rest of the attributes. An example of
  # when this would be useful is with Devise; you can't pass +password+ in the
  # create method, so specifying +unique_columns+ on everything except
  # +password+ allows it to be passed as an attribute to the +first_or_create+
  # call.
  #   require 'planter'
  #   class UsersSeeder < Planter::Seeder
  #     seeding_method :data_array, unique_columns: %i[username email]
  #     def data
  #       [{username: 'foo', email: 'bar', password: 'Example'}]
  #     end
  #   end
  #
  # If you need to seed a different way, put your own custom +seed+ method in
  # your seeder class and do whatever needs to be done.
  class Seeder
    ##
    # The allowed seeding methods.
    #
    # @return [Array]
    SEEDING_METHODS = %i[csv data_array].freeze

    ##
    # Array of hashes used to create records. Your class must set this
    # attribute when using +data_array+ seeding method, although it's probably
    # more likely that you'll want to define a method that returns a new set of
    # data each time (via +Faker+, +Array#sample+, etc.). When using +csv+,
    # +data+ will be set to the data within the csv. You can override this.
    #
    # @return [Array]
    attr_reader :data

    ##
    # What trim mode should ERB use?
    #
    # @return [String]
    class_attribute :erb_trim_mode

    ##
    # When creating a record, the fields that will be used to look up the
    # record. If it already exists, a new one will not be created.
    #
    # @return [Array]
    class_attribute :unique_columns

    ##
    # The model for the table being seeded. If the model name you need is
    # different, change via +seeding_method+.
    #
    # @return [String]
    class_attribute :model

    ##
    # The model of the parent. When provided with +association+, records in the
    # +data+ array, will be created for each record in the parent table. Your
    # class must set this attribute via +seeding_method+.
    #
    # @return [String]
    class_attribute :parent

    ##
    # The number of records to create from each record in the +data+ array. If
    # nil, defaults to 1, but you can override this in your class via
    # +seeding_method+.
    #
    # @return [Integer]
    class_attribute :number_of_records

    ##
    # The csv file corresponding to the model.
    #
    # @return [String]
    class_attribute :csv_name

    ##
    # The seeding method specified.
    #
    # @return [Symbol]
    class_attribute :seed_method

    ##
    # If your class is going to use the inherited +seed+ method, you must tell
    # it which +seeding_method+ to use. The argument to this method must be
    # included in the +SEEDING_METHODS+ array.
    #
    # @param [Symbol] seed_method
    #
    # @kwarg [Integer] number_of_records
    #
    # @kwarg [String] model
    #
    # @kwarg [Symbol, String] parent
    #
    # @kwarg [Symbol, String] csv_name
    #
    # @kwarg [Symbol, String] unique_columns
    #
    # @kwarg [String] erb_trim_mode
    #
    # @example
    #   require 'planter'
    #   class UsersSeeder < Planter::Seeder
    #     seeding_method :csv,
    #       number_of_records: 2,
    #       model: 'User'
    #       parent: :person,
    #       csv_name: :awesome_users,
    #       unique_columns %i[username email],
    #       erb_trim_mode: '<>'
    #   end
    def self.seeding_method(
      seed_method,
      number_of_records: 1,
      model: nil,
      parent: nil,
      csv_name: nil,
      unique_columns: nil,
      erb_trim_mode: nil
    )
      if !SEEDING_METHODS.include?(seed_method.intern)
        raise ArgumentError, "Method must be: #{SEEDING_METHODS.join(', ')}"
      end

      self.seed_method = seed_method
      self.number_of_records = number_of_records
      self.model = model || to_s.delete_suffix('Seeder').singularize
      self.parent = parent
      self.csv_name = csv_name || to_s.delete_suffix('Seeder').underscore
      self.erb_trim_mode = erb_trim_mode || Planter.config.erb_trim_mode
      self.unique_columns =
        case unique_columns
        when String, Symbol then [unique_columns.intern]
        when Array then unique_columns.map(&:intern)
        end
    end

    ##
    # The default seed method. To use this method, your class must provide a
    # valid +seeding_method+, and not implement its own +seed+ method.
    def seed
      validate_attributes
      extract_data_from_csv if seed_method == :csv

      parent ? create_records_from_parent : create_records
    end

    protected

    ##
    # Creates records from the +data+ attribute.
    def create_records
      data.each { |record| create_record(record) }
    end

    ##
    # Create records from the +data+ attribute for each record in the +parent+.
    def create_records_from_parent
      parent_model.constantize.pluck(primary_key).each do |parent_id|
        data.each { |record| create_record(record, parent_id: parent_id) }
      end
    end

    def create_record(record, parent_id: nil)
      number_of_records.times do
        unique, attrs = split_record(record)
        model.constantize.where(
          unique.tap { |u| u[foreign_key] = parent_id if parent_id }
        ).first_or_create!(attrs)
      end
    end

    def validate_attributes # :nodoc:
      case seed_method.intern
      when :csv
        raise "Couldn't find csv for #{model}" unless full_csv_name
      when :data_array
        raise 'data is not defined in the seeder' if public_send(:data).nil?
      else
        raise 'seeding_method not defined in the seeder'
      end
    end

    def split_record(rec) # :nodoc:
      return [rec, {}] unless unique_columns

      u = unique_columns.each_with_object({}) { |c, h| h[c] = rec.delete(c) }
      [u, rec]
    end

    def association_options
      @association_options ||=
        model.constantize.reflect_on_association(parent).options
    end

    def primary_key
      @primary_key ||=
        association_options.fetch(:primary_key, :id)
    end

    def foreign_key
      @foreign_key ||=
        association_options.fetch(:foreign_key, "#{parent}_id")
    end

    def parent_model
      @parent_model ||=
        association_options.fetch(:class_name, parent.to_s.classify)
    end

    def full_csv_name
      @full_csv_name ||=
        %W[#{csv_name}.csv #{csv_name}.csv.erb #{csv_name}.erb.csv]
          .map { |f| Rails.root.join(Planter.config.csv_files_directory, f).to_s }
          .find { |f| ::File.file?(f) }
    end

    def extract_data_from_csv
      contents = ::File.read(full_csv_name)
      if full_csv_name.include?('.erb')
        contents = ERB.new(contents, trim_mode: erb_trim_mode).result(binding)
      end

      @data ||= ::CSV.parse(
        contents,
        headers: true,
        header_converters: :symbol
      ).map(&:to_hash)
    end
  end
end
