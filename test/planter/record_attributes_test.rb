require "test_helper"

class Planter::RecordAttributesTest < ActiveSupport::TestCase
  test "evaluates transformations for each prepared record" do
    sequence = 0
    record_attributes = Planter::RecordAttributes.new(
      context: context,
      adapter: adapter,
      transformations_provider: lambda {
        sequence += 1
        {slug: ->(value) { "#{value}-#{sequence}" }}
      }
    )

    first_lookup_attributes, = record_attributes.prepare({slug: "widget"})
    second_lookup_attributes, = record_attributes.prepare({slug: "widget"})

    assert_equal({slug: "widget-1"}, first_lookup_attributes)
    assert_equal({slug: "widget-2"}, second_lookup_attributes)
  end

  test "caches table columns for repeated records" do
    adapter = CountingAdapter.new
    record_attributes = Planter::RecordAttributes.new(
      context: context,
      adapter: adapter,
      transformations_provider: -> {}
    )

    record_attributes.prepare({slug: "first"})
    record_attributes.prepare({slug: "second"})

    assert_equal 1, adapter.table_columns_calls
  end

  test "caches foreign key for repeated parent records" do
    adapter = CountingAdapter.new
    record_attributes = Planter::RecordAttributes.new(
      context: context(parent: :account),
      adapter: adapter,
      transformations_provider: -> {}
    )

    record_attributes.prepare({slug: "first"}, parent_id: 1)
    record_attributes.prepare({slug: "second"}, parent_id: 2)

    assert_equal 1, adapter.foreign_key_calls
  end

  private

  def context(parent: nil)
    Planter::SeedContext.new(
      table_name: :widgets,
      seed_method: :data_array,
      csv_name: :widgets,
      parent: parent,
      number_of_records: 1,
      unique_columns: nil,
      erb_trim_mode: nil
    )
  end

  def adapter
    CountingAdapter.new
  end

  class CountingAdapter
    attr_reader :foreign_key_calls, :table_columns_calls

    def initialize
      @foreign_key_calls = 0
      @table_columns_calls = 0
    end

    def foreign_key(context:)
      @foreign_key_calls += 1
      :account_id
    end

    def table_columns(context:)
      @table_columns_calls += 1
      %w[slug account_id]
    end
  end
end
