# frozen_string_literal: true

module Planter
  ##
  # Prepares seed records for adapter persistence.
  class RecordAttributes
    ##
    # Create a record attribute preparer.
    #
    # @param [Planter::SeedContext] context seeder configuration
    #
    # @param [Object] adapter configured persistence adapter
    #
    # @param [#call] transformations_provider returns value transformations by
    #   field
    def initialize(context:, adapter:, transformations_provider:)
      @context = context
      @adapter = adapter
      @transformations_provider = transformations_provider
      @warned_non_column_lookup_attributes = []
    end

    ##
    # Prepare lookup and create attributes for adapter persistence.
    #
    # @param [Hash] record seed record attributes
    #
    # @param [Object, nil] parent_id parent record id
    #
    # @return [Array<Hash, Hash>]
    def prepare(record, parent_id: nil)
      lookup_attributes, create_attributes = split_record(apply_transformations(record))
      lookup_attributes = lookup_attributes.merge(foreign_key => parent_id) if parent_id

      filter_lookup_attributes(lookup_attributes, create_attributes)
    end

    private

    attr_reader :context, :adapter, :transformations_provider

    def apply_transformations(record)
      transformations = transformations_provider.call
      return record if transformations.nil?

      record.map { |field, value| map_record(field, value, record, transformations) }.to_h
    end

    def map_record(field, value, record, transformations)
      [
        field,
        transformations.key?(field) ? transform(field, value, record, transformations) : value
      ]
    end

    def transform(field, value, record, transformations)
      case transformations[field].arity
      when 0 then transformations[field].call
      when 1 then transformations[field].call(value)
      when 2 then transformations[field].call(value, record)
      end
    end

    def split_record(record)
      return [record, {}] unless context.unique_columns

      lookup_attributes = context.unique_columns.each_with_object({}) do |column, attrs|
        attrs[column] = record[column]
      end
      [lookup_attributes, record.except(*context.unique_columns)]
    end

    def filter_lookup_attributes(lookup_attributes, create_attributes)
      native_lookup_attributes = lookup_attributes.select do |field, _value|
        table_columns.include?(field.to_s)
      end
      non_column_lookup_attributes = lookup_attributes.except(*native_lookup_attributes.keys)

      warn_non_column_lookup_attributes(non_column_lookup_attributes.keys) if non_column_lookup_attributes.any?

      if native_lookup_attributes.empty?
        raise "No native lookup columns found for #{context.table_name}. " \
          "Add a native table column to the seed data or unique_columns."
      end

      [
        native_lookup_attributes,
        non_column_lookup_attributes.merge(create_attributes)
      ]
    end

    def warn_non_column_lookup_attributes(fields)
      warning_key = fields.map(&:to_s).sort
      return if warned_non_column_lookup_attributes.include?(warning_key)

      warned_non_column_lookup_attributes << warning_key
      warn(
        "WARNING: Planter moved non-column lookup attributes for #{context.table_name} " \
        "into create attributes: #{warning_key.join(", ")}"
      )
    end

    def foreign_key
      @foreign_key ||= adapter.foreign_key(context: context)
    end

    def table_columns
      @table_columns ||= adapter.table_columns(context: context).map(&:to_s)
    end

    attr_reader :warned_non_column_lookup_attributes
  end
end
