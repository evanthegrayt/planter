require "test_helper"

class Planter::SeedContextTest < ActiveSupport::TestCase
  test "normalizes adapter-facing seeder configuration" do
    context = Planter::SeedContext.new(
      table_name: :users,
      seed_method: "csv",
      csv_name: :people,
      parent: :account,
      number_of_records: 2,
      unique_columns: %i[email username],
      erb_trim_mode: "<>",
      adapter_options: {"validation_failure" => "warn", "custom_option" => false}
    )

    assert_equal "users", context.table_name
    assert_equal :csv, context.seed_method
    assert_equal "people", context.csv_name
    assert_equal :account, context.parent
    assert_equal 2, context.number_of_records
    assert_equal %i[email username], context.unique_columns
    assert_equal "<>", context.erb_trim_mode
    assert_equal({validation_failure: "warn", custom_option: false}, context.adapter_options)
  end

  test "defaults adapter options to an empty hash" do
    context = Planter::SeedContext.new(
      table_name: :users,
      seed_method: :csv,
      csv_name: :people,
      parent: nil,
      number_of_records: 1,
      unique_columns: nil,
      erb_trim_mode: nil
    )

    assert_equal({}, context.adapter_options)
  end
end
