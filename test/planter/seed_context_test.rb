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
      erb_trim_mode: "<>"
    )

    assert_equal "users", context.table_name
    assert_equal :csv, context.seed_method
    assert_equal "people", context.csv_name
    assert_equal :account, context.parent
    assert_equal 2, context.number_of_records
    assert_equal %i[email username], context.unique_columns
    assert_equal "<>", context.erb_trim_mode
  end
end
