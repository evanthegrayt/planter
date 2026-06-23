# frozen_string_literal: true

module Planter
  module Adapters
    ##
    # Default adapter for seeding Active Record models.
    #
    # Custom adapters should implement this public API:
    # - +create_record(model_name:, lookup_attributes:, create_attributes:)+
    # - +parent_ids(model_name:, parent:)+
    # - +foreign_key(model_name:, parent:)+
    # - +table_names+
    #
    # +model_name+ is the configured seeder model name. +parent+ is the
    # configured parent association name. Adapters are responsible for resolving
    # those values into whatever persistence or reflection objects they need.
    class ActiveRecord
      ##
      # Create a record unless one already exists.
      #
      # @param [String] model_name the model being seeded
      #
      # @param [Hash] lookup_attributes attributes used to find the record
      #
      # @param [Hash] create_attributes additional attributes used only when
      #   creating a new record
      #
      # @return [Object]
      def create_record(model_name:, lookup_attributes:, create_attributes:)
        model_name.constantize
          .where(lookup_attributes)
          .first_or_create!(create_attributes)
      end

      ##
      # Return the parent ids to use when seeding child records.
      #
      # @param [String] model_name the model being seeded
      #
      # @param [String, Symbol] parent the parent association name
      #
      # @return [Array]
      def parent_ids(model_name:, parent:)
        parent_model(model_name, parent).constantize.pluck(primary_key(model_name, parent))
      end

      ##
      # Return the foreign key used to assign a parent id on a child record.
      #
      # @param [String] model_name the model being seeded
      #
      # @param [String, Symbol] parent the parent association name
      #
      # @return [String, Symbol]
      def foreign_key(model_name:, parent:)
        association_options(model_name, parent).fetch(:foreign_key, "#{parent}_id")
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

      def association_options(model_name, parent)
        model_name.constantize.reflect_on_association(parent).options
      end

      def primary_key(model_name, parent)
        association_options(model_name, parent).fetch(:primary_key, :id)
      end

      def parent_model(model_name, parent)
        association_options(model_name, parent).fetch(:class_name, parent.to_s.classify)
      end
    end
  end
end
