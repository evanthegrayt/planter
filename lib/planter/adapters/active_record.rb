# frozen_string_literal: true

module Planter
  ##
  # Namespace for persistence adapters used by Planter seeders.
  module Adapters
    ##
    # Default adapter for seeding Active Record models.
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
        model(context)
          .where(lookup_attributes)
          .first_or_create!(create_attributes)
      end

      ##
      # Return the parent ids to use when seeding child records.
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
        context.table_name.classify.constantize
      end

      def association_options(context)
        model(context).reflect_on_association(context.parent).options
      end

      def primary_key(context)
        association_options(context).fetch(:primary_key, :id)
      end

      def parent_model(context)
        association_options(context).fetch(:class_name, context.parent.to_s.classify)
      end
    end
  end
end
