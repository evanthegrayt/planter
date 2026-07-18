# frozen_string_literal: true

module Planter
  ##
  # Namespace for persistence adapters used by Planter seeders.
  module Adapters
    ##
    # Default adapter for seeding Active Record tables.
    #
    # When a table maps to an Active Record model, records are created through
    # that model. Tables without a matching model, such as join tables, are
    # seeded directly through the database connection.
    #
    # Custom adapters should implement this public API:
    # - +create_record(context:, lookup_attributes:, create_attributes:)+
    # - +parent_ids(context:)+
    # - +foreign_key(context:)+
    # - +table_columns(context:)+
    # - +table_names+
    #
    # +context+ is a +Planter::SeedContext+. Adapters are responsible for
    # resolving those values into whatever persistence or reflection objects
    # they need.
    class ActiveRecord
      ##
      # Validation failure actions supported by the Active Record adapter.
      #
      # @return [Array<Symbol>]
      VALIDATION_FAILURE_ACTIONS = %i[raise warn].freeze

      ##
      # Configuration for the Active Record adapter.
      class Configuration
        ##
        # How model validation failures should be handled when creating records.
        #
        # @return [Symbol]
        attr_reader :validation_failure

        ##
        # Create a new Active Record adapter configuration.
        def initialize
          @validation_failure = :raise
        end

        ##
        # Set how model validation failures should be handled.
        #
        # @param [String, Symbol] action either +:raise+ or +:warn+
        def validation_failure=(action)
          action = action.to_sym
          unless VALIDATION_FAILURE_ACTIONS.include?(action)
            raise ArgumentError, "validation_failure must be: #{VALIDATION_FAILURE_ACTIONS.join(", ")}"
          end

          @validation_failure = action
        end
      end

      ##
      # The adapter configuration.
      #
      # @return [Planter::Adapters::ActiveRecord::Configuration]
      attr_reader :configuration

      ##
      # Create a new Active Record adapter.
      #
      # @yield [configuration] optional configuration block
      # @yieldparam configuration [Planter::Adapters::ActiveRecord::Configuration]
      def initialize
        @configuration = Configuration.new
        yield configuration if block_given?
      end

      ##
      # Create a record unless one already exists.
      #
      # @param [Planter::SeedContext] context seeder configuration
      #
      # @param [Hash] lookup_attributes attributes used to find the record
      #
      # @param [Hash] create_attributes additional attributes used only when
      #   creating a new record
      #
      # @return [Object]
      def create_record(context:, lookup_attributes:, create_attributes:)
        if (model = model(context))
          create_model_record(model, context, lookup_attributes, create_attributes)
        else
          create_table_record(context, lookup_attributes, create_attributes)
        end
      end

      ##
      # Return the parent ids to use when seeding child records.
      #
      # The Active Record adapter resolves parents through model associations.
      # Tables without matching models should use a custom adapter for parent
      # seeding.
      #
      # @param [Planter::SeedContext] context seeder configuration
      #
      # @return [Array]
      def parent_ids(context:)
        parent_model(context).constantize.pluck(primary_key(context))
      end

      ##
      # Return the foreign key used to assign a parent id on a child record.
      #
      # The Active Record adapter resolves foreign keys through model
      # associations. Tables without matching models should use a custom adapter
      # for parent seeding.
      #
      # @param [Planter::SeedContext] context seeder configuration
      #
      # @return [String, Symbol]
      def foreign_key(context:)
        association_options(context).fetch(:foreign_key, "#{context.parent}_id")
      end

      ##
      # Return native table columns for the table being seeded.
      #
      # @param [Planter::SeedContext] context seeder configuration
      #
      # @return [Array<String>]
      def table_columns(context:)
        ::ActiveRecord::Base.connection.columns(context.table_name).map(&:name)
      end

      ##
      # Return application table names that can have seeders generated.
      #
      # @return [Array<String>]
      def table_names
        ::ActiveRecord::Base.connection.tables.reject do |table|
          %w[ar_internal_metadata schema_migrations].include?(table)
        end
      end

      private

      def model(context)
        context.table_name.classify.safe_constantize&.then do |model|
          model if model.respond_to?(:table_name) && model.table_name == context.table_name
        end
      end

      def create_model_record(model, context, lookup_attributes, create_attributes)
        relation = model.where(lookup_attributes)
        case validation_failure(context)
        when :raise
          relation.first_or_create!(create_attributes)
        when :warn
          record = relation.first_or_create(create_attributes)
          warn_validation_failure(context, lookup_attributes, record) if failed_create?(record)
          record
        end
      end

      def validation_failure(context)
        context_action = context.validation_failure if context.respond_to?(:validation_failure)
        action = context_action || configuration.validation_failure
        action = action.to_sym
        return action if VALIDATION_FAILURE_ACTIONS.include?(action)

        raise ArgumentError, "validation_failure must be: #{VALIDATION_FAILURE_ACTIONS.join(", ")}"
      end

      def failed_create?(record)
        record == false || (record.respond_to?(:persisted?) && !record.persisted?)
      end

      def warn_validation_failure(context, lookup_attributes, record)
        warn(
          [
            "WARNING: Planter could not create #{context.table_name} with lookup attributes",
            lookup_attributes.inspect,
            validation_errors(record)
          ].compact.join(" ")
        )
      end

      def validation_errors(record)
        return unless record.respond_to?(:errors) && record.errors.any?

        "Errors: #{record.errors.full_messages.join(", ")}"
      end

      def association_options(context)
        model!(context).reflect_on_association(context.parent).options
      end

      def primary_key(context)
        association_options(context).fetch(:primary_key, :id)
      end

      def parent_model(context)
        association_options(context).fetch(:class_name, context.parent.to_s.classify)
      end

      def model!(context)
        model(context) || raise(
          "Planter's Active Record adapter requires a model-backed table for " \
          "parent seeding. Define a model for #{context.table_name} or use a " \
          "custom adapter."
        )
      end

      def create_table_record(context, lookup_attributes, create_attributes)
        find_table_record(context, lookup_attributes) ||
          insert_table_record(context, lookup_attributes.merge(create_attributes))
      end

      def find_table_record(context, lookup_attributes)
        connection.select_one(
          [
            "SELECT * FROM #{quote_table(context.table_name)}",
            "WHERE #{where_clause(lookup_attributes)}",
            "LIMIT 1"
          ].join(" ")
        )
      end

      def insert_table_record(context, attributes)
        connection.execute(
          [
            "INSERT INTO #{quote_table(context.table_name)}",
            "(#{attributes.keys.map { |key| quote_column(key) }.join(", ")})",
            "VALUES (#{attributes.values.map { |value| connection.quote(value) }.join(", ")})"
          ].join(" ")
        )
      end

      def where_clause(attributes)
        attributes.map do |key, value|
          if value.nil?
            "#{quote_column(key)} IS NULL"
          else
            "#{quote_column(key)} = #{connection.quote(value)}"
          end
        end.join(" AND ")
      end

      def quote_table(table_name)
        connection.quote_table_name(table_name)
      end

      def quote_column(column_name)
        connection.quote_column_name(column_name)
      end

      def connection
        ::ActiveRecord::Base.connection
      end
    end
  end
end
