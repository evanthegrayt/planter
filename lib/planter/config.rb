module Planter
  ##
  # Configure the application seeder.
  #
  # @example
  #   Planter.configure { |seeder| seeder.tables = %i[users] }
  class Config
    ##
    # Tell the application where the seeder classes are kept. Must be a fully
    # qualified path.
    #
    # @param [String] directory
    #
    # @return [String]
    attr_accessor :seeds_directory

    ##
    # Tell the application where the seed files are kept. Must be a fully
    # qualified path.
    #
    # @param [String] directory
    #
    # @return [String]
    attr_accessor :seed_files_directory

    ##
    # Tell the application what tables to seed. Elements should be in the correct
    # order, and can be strings or symbols.
    #
    # @param [Array] tables
    #
    # @return [Array]
    attr_accessor :tables

    def initialize
      @seed_files_directory = Rails.root.join('db', 'seed_files')
      @seeds_directory = Rails.root.join('db', 'seeds')
    end
  end
end
