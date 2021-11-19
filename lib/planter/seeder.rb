# frozen_string_literal: true

module Planter
  ##
  # Class that seeders should inherit from. Seeder files should be in
  # +db/seeds+, and named +TABLE_seeder.rb+, where +TABLE+ is the name of the
  # table being seeded (I.E. +users_seeder.rb+). If your seeder is named
  # differently than the table, you'll need to specify the table with the
  # +model+ option. The seeder's class name should be the same as the file
  # name, but camelized. So, +UsersSeeder+. The directory where the seeder
  # files are located can be changed via an initializer.
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
  # attribute, so the most you have to do it create instance variables in your
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
  # In both of the above methods, you can specify +parent_model+ and
  # +association+. If specified, records will be created via that parent
  # model's association. If +association+ is not provided, it will be assumed
  # to be the model name, pluralized and snake-cased (implying a +has_many+
  # relationship).  For example, if we're seeding the users table, and the
  # model is +User+, the association will default to +users+.
  #   require 'planter'
  #   class UsersSeeder < Planter::Seeder
  #     seeding_method :data_array, parent_model: 'Person', association: :users
  #     def data
  #       [{foo: 'bar', baz: 'bar'}]
  #     end
  #   end
  #
  # You can also set +number_of_records+ to determine how many times each
  # record in the +data+ array will get created. The default is 1. Note that if
  # this attribute is set alongside +parent_model+ and +association+,
  # +number_of_records+ will be how many records will be created for each
  # record in the parent table.
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
    #       parent_model: 'Person',
    #       association: :users,
    #       csv_name: :awesome_users,
    #       unique_columns %i[username email],
    #       erb_trim_mode: '<>'
    #   end
    def self.seeding_method(
      method,
      number_of_records: 1,
      model: nil,
      parent_model: nil,
      association: nil,
      csv_name: nil,
      unique_columns: nil,
      erb_trim_mode: nil
    )
      if !SEEDING_METHODS.include?(method.intern)
        raise ArgumentError, "Method must be one of #{SEEDING_METHODS.join(', ')}"
      elsif association && !parent_model
        raise ArgumentError, "Must specify :parent_model with :association"
      end

      @seeding_method = method
      @number_of_records = number_of_records
      @model = model || to_s.delete_suffix('Seeder').singularize
      @parent_model = parent_model
      @association = @parent_model && (association || determine_association)
      @csv_file = determine_csv_filename(csv_name) if @seeding_method == :csv
      @erb_trim_mode = erb_trim_mode || Planter.config.erb_trim_mode
      @unique_columns =
        case unique_columns
        when String, Symbol then [unique_columns.intern]
        when Array then unique_columns.map(&:intern)
        end
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
        return fname if ::File.file?(fname)
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
    # When creating a record, the fields that will be used to look up the
    # record. If it already exists, a new one will not be created.
    #
    # @return [Array]
    def unique_columns
      @unique_columns ||= self.class.instance_variable_get('@unique_columns')
    end

    ##
    # What trim mode should ERB use?
    #
    # @return [String]
    def erb_trim_mode
      @erb_trim_mode ||= self.class.instance_variable_get('@erb_trim_mode')
    end

    ##
    # Creates records from the +data+ attribute.
    def create_records
      data.each do |rec|
        number_of_records.times do
          rec.transform_values { |value| value == 'NULL' ? nil : value }
          unique, attrs = split_record(rec)
          model.constantize.where(unique).first_or_create!(attrs)
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

    def create_method # :nodoc:
      parent_model.constantize.reflect_on_association(
        association
      ).macro.to_s.include?('many') ? :create_has_many : :create_has_one
    end

    def create_has_many(assoc_rec, association, rec) # :nodoc:
      unique, attrs = split_record(rec)
      assoc_rec.public_send(association).where(unique).first_or_create!(attrs)
    end

    def create_has_one(assoc_rec, association, rec) # :nodoc:
      if assoc_rec.public_send(association)
        assoc_rec.public_send(association).update_attributes(rec)
      else
        assoc_rec.public_send("create_#{association}", rec)
      end
    end

    def validate_attributes # :nodoc:
      case seeding_method.intern
      when :csv
        contents = ::File.read(csv_file)
        if csv_file.end_with?('.erb')
          contents = ERB.new(contents, trim_mode: erb_trim_mode).result(binding)
        end

        @data ||= ::CSV.parse(
          contents, headers: true, header_converters: :symbol
        ).map(&:to_hash)
      when :data_array
        raise "Must define '@data'" if public_send(:data).nil?
      else
        raise("Must set 'seeding_method'")
      end
    end

    def split_record(rec) # :nodoc:
      return [rec, {}] unless unique_columns
      u = unique_columns.each_with_object({}) { |c, h| h[c] = rec.delete(c) }
      [u, rec]
    end
  end
end
