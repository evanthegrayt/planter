require "test_helper"
require "planter/adapters/active_record"

class Planter::Adapters::ActiveRecordTest < ActiveSupport::TestCase
  setup do
    @adapter = Planter::Adapters::ActiveRecord.new
  end

  test "creates records from lookup and create attributes" do
    record = @adapter.create_record(
      context: context(table_name: :users),
      lookup_attributes: {email: "adapter@example.com"},
      create_attributes: {username: "adapter"}
    )
    @adapter.create_record(
      context: context(table_name: :users),
      lookup_attributes: {email: "adapter@example.com"},
      create_attributes: {username: "changed"}
    )

    users = User.where(email: "adapter@example.com")
    assert_equal 1, users.count
    assert_equal "adapter", users.first.username
    assert_instance_of User, record
  end

  test "creates model-less table records directly" do
    user = User.create!(email: "join-user@example.com", username: "join-user")
    role = Role.create!(name: "join-role")

    @adapter.create_record(
      context: context(table_name: :roles_users),
      lookup_attributes: {user_id: user.id, role_id: role.id},
      create_attributes: {}
    )
    @adapter.create_record(
      context: context(table_name: :roles_users),
      lookup_attributes: {user_id: user.id, role_id: role.id},
      create_attributes: {}
    )

    count = ActiveRecord::Base.connection.select_value(
      "SELECT COUNT(*) FROM roles_users WHERE user_id = #{user.id} AND role_id = #{role.id}"
    )
    assert_equal 1, count
  end

  test "finds model-less table records with nil lookup values" do
    user = User.create!(email: "nil-join-user@example.com", username: "nil-join-user")

    @adapter.create_record(
      context: context(table_name: :roles_users),
      lookup_attributes: {user_id: user.id, role_id: nil},
      create_attributes: {}
    )
    @adapter.create_record(
      context: context(table_name: :roles_users),
      lookup_attributes: {user_id: user.id, role_id: nil},
      create_attributes: {}
    )

    count = ActiveRecord::Base.connection.select_value(
      "SELECT COUNT(*) FROM roles_users WHERE user_id = #{user.id} AND role_id IS NULL"
    )
    assert_equal 1, count
  end

  test "returns parent ids from reflected association" do
    user = User.create!(
      email: "parent_ids@example.com",
      username: "parent_ids"
    )

    assert_includes @adapter.parent_ids(context: context(table_name: :addresses, parent: :person)), user.id
  end

  test "returns custom foreign key from reflected association" do
    assert_equal :user_id, @adapter.foreign_key(context: context(table_name: :addresses, parent: :person))
  end

  test "returns default foreign key from reflected association" do
    assert_equal "user_id", @adapter.foreign_key(context: context(table_name: :profiles, parent: :user))
  end

  test "raises a helpful error when parent seeding uses a model-less table" do
    error = assert_raises(RuntimeError) do
      @adapter.foreign_key(context: context(table_name: :roles_users, parent: :user))
    end

    assert_equal(
      "Planter's Active Record adapter requires a model-backed table for parent seeding. " \
        "Define a model for roles_users or use a custom adapter.",
      error.message
    )
  end

  test "returns native table columns" do
    table_columns = @adapter.table_columns(context: context(table_name: :users))

    assert_includes table_columns, "email"
    assert_includes table_columns, "username"
    assert_not_includes table_columns, "phone"
  end

  test "returns native table columns by table name" do
    table_columns = @adapter.table_columns(context: context(table_name: :roles_users))

    assert_equal %w[user_id role_id], table_columns
  end

  test "returns table names without rails metadata tables" do
    table_names = @adapter.table_names

    assert_includes table_names, "users"
    assert_includes table_names, "roles_users"
    assert_not_includes table_names, "ar_internal_metadata"
    assert_not_includes table_names, "schema_migrations"
  end

  private

  def context(table_name:, parent: nil)
    Planter::SeedContext.new(
      table_name: table_name,
      seed_method: :data_array,
      csv_name: table_name,
      parent: parent,
      number_of_records: 1,
      unique_columns: nil,
      erb_trim_mode: nil
    )
  end
end
