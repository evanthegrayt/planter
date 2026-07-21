# frozen_string_literal: true

module Planter
  ##
  # Parameter object carrying normalized seeder configuration into adapters.
  class SeedContext
    ##
    # The table being seeded.
    #
    # @return [String]
    attr_reader :table_name

    ##
    # The configured seeding method.
    #
    # @return [Symbol, nil]
    attr_reader :seed_method

    ##
    # The CSV seed file name without an extension.
    #
    # @return [String]
    attr_reader :csv_name

    ##
    # The adapter-defined parent relation.
    #
    # @return [String, Symbol, nil]
    attr_reader :parent

    ##
    # How many times to create each data record.
    #
    # @return [Integer]
    attr_reader :number_of_records

    ##
    # Columns used to look up existing records.
    #
    # @return [Array<Symbol>, nil]
    attr_reader :unique_columns

    ##
    # The ERB trim mode used for CSV templates.
    #
    # @return [String, nil]
    attr_reader :erb_trim_mode

    ##
    # Adapter-specific options collected from the seeder.
    #
    # Adapters may ignore any options they do not support.
    #
    # @return [Hash]
    attr_reader :adapter_options

    ##
    # Create a new seed context.
    #
    # @param [String, Symbol] table_name
    #
    # @param [String, Symbol, nil] seed_method
    #
    # @param [String, Symbol] csv_name
    #
    # @param [String, Symbol, nil] parent
    #
    # @param [Integer] number_of_records
    #
    # @param [Array<Symbol>, nil] unique_columns
    #
    # @param [String, nil] erb_trim_mode
    #
    # @param [Hash] adapter_options adapter-specific per-seeder options
    def initialize(
      table_name:,
      seed_method:,
      csv_name:,
      parent:,
      number_of_records:,
      unique_columns:,
      erb_trim_mode:,
      adapter_options: {}
    )
      @table_name = table_name.to_s
      @seed_method = seed_method&.intern
      @csv_name = csv_name.to_s
      @parent = parent
      @number_of_records = number_of_records
      @unique_columns = unique_columns
      @erb_trim_mode = erb_trim_mode
      @adapter_options = adapter_options.to_h.transform_keys(&:to_sym)
    end
  end
end
