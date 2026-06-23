require "test_helper"
require "planter/adapters/active_record"

class Planter::Adapters::ActiveRecordTest < ActiveSupport::TestCase
  setup do
    @adapter = Planter::Adapters::ActiveRecord.new
  end

  test "creates records from lookup and create attributes" do
    @adapter.create_record(
      model_name: "User",
      lookup_attributes: {email: "adapter@example.com"},
      create_attributes: {username: "adapter"}
    )
    @adapter.create_record(
      model_name: "User",
      lookup_attributes: {email: "adapter@example.com"},
      create_attributes: {username: "changed"}
    )

    users = User.where(email: "adapter@example.com")
    assert_equal 1, users.count
    assert_equal "adapter", users.first.username
  end

  test "returns parent ids from reflected association" do
    user = User.create!(
      email: "parent_ids@example.com",
      username: "parent_ids"
    )

    assert_includes @adapter.parent_ids(model_name: "Address", parent: :person), user.id
  end

  test "returns custom foreign key from reflected association" do
    assert_equal :user_id, @adapter.foreign_key(model_name: "Address", parent: :person)
  end

  test "returns default foreign key from reflected association" do
    assert_equal "user_id", @adapter.foreign_key(model_name: "Profile", parent: :user)
  end

  test "returns native table columns for model" do
    table_columns = @adapter.table_columns(model_name: "User")

    assert_includes table_columns, "email"
    assert_includes table_columns, "username"
    assert_not_includes table_columns, "phone"
  end

  test "returns table names without rails metadata tables" do
    table_names = @adapter.table_names

    assert_includes table_names, "users"
    assert_includes table_names, "roles_users"
    assert_not_includes table_names, "ar_internal_metadata"
    assert_not_includes table_names, "schema_migrations"
  end
end
