# frozen_string_literal: true

module Planter
  ##
  # Configure the application seeder.
  #
  # @example
  #   Planter.configure { |seeder| seeder.seeders = %i[users] }
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
    # Tell the application what seeders exist. Elements should be in the correct
    # order to seed the tables successfully, and can be strings or symbols.
    #
    # @param [Array] seeders
    #
    # @return [Array]
    attr_accessor :seeders

    ##
    # When true, don't print output when seeding.
    #
    # @param [Boolean] quiet
    #
    # @return [Boolean]
    attr_accessor :quiet

    ##
    # When false, don't print the progress bar.
    #
    # @param [Boolean] progress_bar
    #
    # @return [Boolean]
    attr_accessor :progress_bar

    ##
    # Create a new instance of the config.
    def initialize
      @quiet = false
      @progress_bar = true
      @seeders_directory = ::File.join('db', 'seeds')
      @csv_files_directory = ::File.join('db', 'seed_files')
    end
  end
end
