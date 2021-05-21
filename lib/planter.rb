require "planter/version"
require "planter/railtie"
require 'csv'
require 'planter/config'
require 'planter/seeder'

##
# Class that seeders should inherit from. Seeder files should be in +db/seeds+,
# and named +TABLE_seeder.rb+, where +TABLE+ is the name of the table being
# seeded (I.E. +users_seeder.rb+). The seeder's class name should be the same
# as the file name, but camelized. So, +UsersSeeder+. The directory where the
# seeder files are located can be changed via an initializer.
#
# The most basic way to seed is to have a CSV file with the same name as the
# table in +db/seed_files/+. So, +users.csv+. This CSV should have the table's
# column names as header. To seed using this method, your class should look
# like the following. Note that +:csv_file+ is not required; it defaults to the
# table name with a +csv+ file extension. The directory where the seed files
# are kept can be changed via an initializer.
#   # db/seeds/users_seeder.rb
#   require 'planter'
#   class UsersSeeder < Planter::Seeder
#     seeding_method :standard_csv, csv_file: 'db/seed_files/users.csv'
#   end
#
# Another way to seed is to create records from a data array. To do this, your
# class must implement a +data+ attribute or method, which is an array of
# hashes. Note that this class already provides the +attr_reader+ for this
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
# +association+. If specified, records will be created via that parent model's
# association. If +association+ is not provided, it will be assumed to be the
# model name, pluralized and snake-cased (implying a +has_many+ relationship).
# For example, if we're seeding the users table, and the model is +User+, the
# association will default to +users+.
#   require 'planter'
#   class UsersSeeder < Planter::Seeder
#     seeding_method :data_array, parent_model: 'Person', association: :users
#     def data
#       [{foo: 'bar', baz: 'bar'}]
#     end
#   end
#
# You can also set +number_of_records+ to determine how many times each record
# in the +data+ array will get created. The default is 1. Note that if this
# attribute is set alongside +parent_model+ and +association+,
# +number_of_records+ will be how many records will be created for each record
# in the parent table.
#   require 'planter'
#   class UsersSeeder < Planter::Seeder
#     seeding_method :data_array, number_of_records: 5
#     def data
#       [{foo: 'bar', baz: 'bar'}]
#     end
#   end
#
# If you need to seed a different way, put your own custom +seed+ method in
# your seeder class and do whatever needs to be done.
module Planter
  ##
  # The allowed seeding methods.
  #
  # @return [Array]
  SEEDING_METHODS = %i[standard_csv data_array].freeze

  ##
  # Array of hashes used to create records. Your class must set this attribute
  # when using +data_hash+ seeding method, although it's probably more likely
  # that you'll want to define a method that returns a new set of data each
  # time (via +Faker+, +Array#sample+, etc.). When using +standard_csv+, +data+
  # will be set to the data within the csv. You can override this.
  #
  # @return [Array]
  attr_reader :data

  ##
  # The seeder configuration.
  #
  # @return [Planter::Config]
  def self.config
    @config ||= Planter::Config.new
  end

  ##
  # Quick way of configuring the directories via an initializer.
  #
  # @return [self]
  #
  # @example
  #   Planter.configure do |app_seeder|
  #     app_seeder.tables = %i[users]
  #     app_seeder.seeds_directory = 'db/seeds'
  #     app_seeder.seed_files_directory = 'db/seed_files'
  #   end
  def self.configure
    yield config
    self
  end

  ##
  # This is the method to call from your +db/seeds.rb+. It seeds the tables
  # listed in +Planter.config.tables+. To seed specific tables at
  # runtime, you can set the +TABLES+ environmental variable to a
  # comma-separated list of tables.
  #
  # @example
  #   rails db:seed TABLES=users,accounts
  def self.execute
    tables = ENV['TABLES']&.split(',') || config.tables&.map(&:to_s)
    raise RuntimeError, 'No tables specified; nothing to do' unless tables&.any?

    tables.each do |table|
      require File.join(config.seeds_directory, "#{table}_seeder.rb")
      puts "Seeding #{table}"
      "#{table.camelize}Seeder".constantize.new.seed
    end
  end
end
