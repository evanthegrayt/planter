# frozen_string_literal: true

module Planter
  ##
  # Performs read-only validation of the configured seed plan.
  #
  # The validator checks that requested seeders can be loaded, that built-in
  # seeding methods have the files or data they need, and that the configured
  # adapter exposes Planter's public adapter API.
  class Validator
    ##
    # Structured validation result containing fatal errors and non-fatal
    # warnings.
    class Result
      ##
      # Fatal validation errors.
      #
      # @return [Array<String>]
      attr_reader :errors

      ##
      # Non-fatal validation warnings.
      #
      # @return [Array<String>]
      attr_reader :warnings

      ##
      # Create an empty validation result.
      def initialize
        @errors = []
        @warnings = []
      end

      ##
      # Record a fatal validation error.
      #
      # @param message [String]
      def add_error(message)
        errors << message
      end

      ##
      # Record a non-fatal validation warning.
      #
      # @param message [String]
      def add_warning(message)
        warnings << message
      end

      ##
      # Whether validation completed without fatal errors.
      #
      # @return [Boolean]
      def success?
        errors.empty?
      end
    end

    ##
    # Adapter methods required for Planter's public adapter API.
    #
    # @return [Array<Symbol>]
    REQUIRED_ADAPTER_METHODS = %i[
      create_record
      parent_ids
      foreign_key
      table_columns
      table_names
    ].freeze

    ##
    # Create a validator.
    #
    # @param config [Planter::Config]
    #
    # @param seeders [Array<String>, nil] seeders to validate
    def initialize(config: Planter.config, seeders: nil)
      @config = config
      @seeders = seeders || requested_seeders
      @result = Result.new
    end

    ##
    # Validate the seed plan without creating, updating, or deleting records.
    #
    # @return [Planter::Validator::Result]
    def validate
      seeders_present = validate_seeders_present
      validate_adapter
      validate_seeders if seeders_present
      result
    end

    private

    attr_reader :config, :seeders, :result

    def requested_seeders
      ENV["SEEDERS"]&.split(",") || config.seeders&.map(&:to_s)
    end

    def validate_seeders_present
      return true if seeders.present?

      result.add_error(
        "No seeders configured. Add seeders to config.seeders in " \
        "config/initializers/planter.rb or set SEEDERS."
      )
      false
    end

    def validate_adapter
      REQUIRED_ADAPTER_METHODS.each do |method|
        next if adapter.respond_to?(method)

        result.add_error("Configured adapter must respond to ##{method}.")
      end
    end

    def validate_seeders
      seeders.each { |seeder| validate_seeder(seeder) }
    end

    def validate_seeder(seeder)
      return unless require_seeder(seeder)

      seeder_class = constantize_seeder(seeder)
      return unless seeder_class
      return unless validate_seeder_class(seeder, seeder_class)
      return if custom_seed?(seeder_class)

      validate_default_seeder(seeder, seeder_class)
    end

    def require_seeder(seeder)
      path = seeder_path(seeder)
      unless ::File.file?(path)
        result.add_error("Seeder file not found for #{seeder}: #{path}.")
        return false
      end

      require path
      true
    rescue LoadError, SyntaxError, StandardError => error
      result.add_error(
        "Could not load seeder file for #{seeder}: #{error.class}: #{error.message}."
      )
      false
    end

    def constantize_seeder(seeder)
      "#{seeder.camelize}Seeder".constantize
    rescue NameError
      result.add_error("Seeder class #{seeder.camelize}Seeder could not be constantized.")
      nil
    end

    def validate_seeder_class(seeder, seeder_class)
      return true if seeder_class <= Planter::Seeder

      result.add_error("#{seeder.camelize}Seeder must inherit from Planter::Seeder.")
      false
    end

    def custom_seed?(seeder_class)
      seeder_class.instance_method(:seed).owner != Planter::Seeder
    end

    def validate_default_seeder(seeder, seeder_class)
      unless Planter::Seeder::SEEDING_METHODS.include?(seeder_class.seed_method&.intern)
        result.add_error("#{seeder.camelize}Seeder must define a valid seeding_method.")
        return
      end

      case seeder_class.seed_method.intern
      when :csv
        validate_csv_seeder(seeder, seeder_class)
      when :data_array
        validate_data_array_seeder(seeder, seeder_class)
      end
    end

    def validate_csv_seeder(seeder, seeder_class)
      seeder_instance = build_seeder(seeder, seeder_class)
      return unless seeder_instance

      context = context_for(seeder_class)
      data_source = Planter::CsvDataSource.new(context: context, seeder: seeder_instance)
      unless data_source.path
        result.add_error("CSV seed file not found for #{seeder_class.table_name}.")
        return
      end

      return unless adapter.respond_to?(:table_columns)

      validate_csv_headers(data_source.path, context, seeder_instance)
    end

    def validate_data_array_seeder(seeder, seeder_class)
      seeder_instance = build_seeder(seeder, seeder_class)
      return unless seeder_instance

      return unless seeder_instance.public_send(:data).nil?

      result.add_error("#{seeder.camelize}Seeder must define non-nil data.")
    rescue => error
      result.add_error(
        "#{seeder.camelize}Seeder data could not be read: " \
        "#{error.class}: #{error.message}."
      )
    end

    def validate_csv_headers(path, context, seeder_instance)
      headers = csv_headers(path, context, seeder_instance)
      return if headers.nil?

      table_columns = adapter.table_columns(context: context).map(&:to_s)
      lookup_fields = csv_lookup_fields(headers, context)
      native_lookup_fields = lookup_fields.select do |field|
        table_columns.include?(field.to_s)
      end
      non_column_lookup_fields = lookup_fields - native_lookup_fields

      if native_lookup_fields.empty?
        result.add_error(
          "No native lookup columns found for #{context.table_name}. " \
          "Add a native table column to the seed data or unique_columns."
        )
      end

      return if non_column_lookup_fields.empty?

      result.add_warning(
        "Planter will move non-column lookup attributes for #{context.table_name} " \
        "into create attributes: #{non_column_lookup_fields.map(&:to_s).sort.join(", ")}."
      )
    rescue => error
      result.add_error(
        "CSV headers could not be read for #{context.table_name}: " \
        "#{error.class}: #{error.message}."
      )
    end

    def csv_headers(path, context, seeder_instance)
      header = ::File.foreach(path).first.to_s
      if path.include?(".erb") && header.include?("<%")
        header = ERB.new(header, trim_mode: context.erb_trim_mode).result(
          seeder_instance.instance_eval { binding }
        )
      end

      ::CSV.parse(header, headers: true, header_converters: :symbol).headers
    end

    def csv_lookup_fields(headers, context)
      fields = context.unique_columns || headers
      fields = fields.compact.map(&:to_sym)

      if context.parent && adapter.respond_to?(:foreign_key)
        fields << adapter.foreign_key(context: context).to_sym
      end

      fields
    end

    def build_seeder(seeder, seeder_class)
      seeder_class.new
    rescue => error
      result.add_error(
        "#{seeder.camelize}Seeder could not be initialized: " \
        "#{error.class}: #{error.message}."
      )
      nil
    end

    def context_for(seeder_class)
      Planter::SeedContext.new(
        table_name: seeder_class.table_name,
        seed_method: seeder_class.seed_method,
        csv_name: seeder_class.csv_name,
        parent: seeder_class.parent,
        number_of_records: seeder_class.number_of_records,
        unique_columns: seeder_class.unique_columns,
        erb_trim_mode: seeder_class.erb_trim_mode
      )
    end

    def seeder_path(seeder)
      Rails.root.join(config.seeders_directory, "#{seeder}_seeder.rb").to_s
    end

    def adapter
      @adapter ||= config.adapter
    end
  end
end
