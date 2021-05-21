# frozen_string_literal: true

module Planter
  ##
  # Configure the application seeder.
  #
  # @example
  #   Planter.configure { |seeder| seeder.tables = %i[users] }
  class Config
    ##
    # Tell the application where the seeder classes are kept. Must be a path
    # relative to +Rails.root+.
    #
    # @param [String] directory
    #
    # @return [String]
    attr_accessor :seeders_directory

    ##
    # Tell the application where the CSV seed files are kept. Must be a path
    # relative to +Rails.root+.
    #
    # @param [String] directory
    #
    # @return [String]
    attr_accessor :csv_files_directory

    ##
    # Tell the application what tables to seed. Elements should be in the correct
    # order, and can be strings or symbols.
    #
    # @param [Array] tables
    #
    # @return [Array]
    attr_accessor :tables

    ##
    # When true, don't print output when seeding.
    #
    # @param [Boolean] quiet
    #
    # @return [Boolean]
    attr_accessor :quiet

    ##
    # Create a new instance of the config.
    def initialize
      @quiet = false
      @seeders_directory = ::File.join('db', 'seeds')
      @csv_files_directory = ::File.join('db', 'seed_files')
    end
  end
end
