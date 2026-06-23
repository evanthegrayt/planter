require "test_helper"

class Planter::SeederTest < ActiveSupport::TestCase
  setup do
    reset_seeder_class_attributes
    Planter.reset_config
    Planter.configure do |c|
      c.seeders = %i[users addresses bios roles comments]
      c.quiet = true
      c.erb_trim_mode = "<>"
    end
  end

  teardown do
    reset_seeder_class_attributes
    Planter.reset_config
  end

  test "it has seeding method constant" do
    assert_equal %i[csv data_array], Planter::Seeder::SEEDING_METHODS
  end

  test "attributes are protected" do
    assert_raise(NameError) { seeder.seed_method }
  end

  test "seeding method rejects unsupported methods" do
    error = assert_raise(ArgumentError) do
      Class.new(Planter::Seeder) { seeding_method :json }
    end

    assert_equal "Method must be: csv, data_array", error.message
  end

  test "seed raises a helpful error when seeding method is not configured" do
    error = assert_raise(RuntimeError) { Planter::Seeder.new.seed }

    assert_equal "seeding_method not defined in the seeder", error.message
  end

  test "data array seed requires data" do
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method :data_array, model: "User"
    end

    error = assert_raise(RuntimeError) { seeder_class.new.seed }

    assert_equal "data is not defined in the seeder", error.message
  end

  test "csv seed requires a matching csv file" do
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method :csv, model: "User", csv_name: :missing_users
    end

    error = assert_raise(RuntimeError) { seeder_class.new.seed }

    assert_equal "Couldn't find csv for User", error.message
  end

  test "csv with unique columns" do
    Planter.seed
    assert_equal 2, User.count
    assert_equal "test1@example.com", User.first.email
    assert_equal "test2", User.last.username
  end

  test "csv erb with parent and transformation" do
    Planter.seed
    assert_equal 4, Comment.count
    assert_equal(
      User.pluck(:id).index_with { 2 },
      Comment.group(:user_id).count
    )
    assert_equal 20, Comment.last.upvotes
    assert_equal "This is a TEST 1", Comment.first.message
  end

  test "transformations can ignore input or use the whole record" do
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method :data_array, model: "User", unique_columns: :email

      def data
        [{
          email: "before@example.com",
          username: "before"
        }]
      end

      def transformations
        {
          email: -> { "after@example.com" },
          username: ->(_value, row) { row[:email].split("@").first }
        }
      end
    end

    seeder_class.new.seed

    user = User.find_by!(email: "after@example.com")
    assert_equal "before", user.username
  end

  test "has_one data_array with model parent and association" do
    Planter.seed
    assert_equal 2, Profile.count
    assert_equal(
      User.pluck(:id).index_with { 1 },
      Profile.group(:user_id).count
    )
  end

  test "has_many data_array with unique parent does not mutate records" do
    Planter.seed
    assert_equal User.count, Address.count
    assert_equal(
      User.pluck(:id).index_with { 1 },
      Address.group(:user_id).count
    )
    assert_equal 0, Address.where(city: nil, state: nil).count
  end

  test "data_array with parent reevaluates data for number_of_records" do
    Planter.seed
    Address.delete_all
    parent_ids = User.pluck(:id)
    sequence = 0
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method(
        :data_array,
        model: "Address",
        parent: :person,
        number_of_records: 4
      )

      define_method(:data) do
        sequence += 1
        [{
          street_1: "#{sequence} Main St",
          city: "City #{sequence}",
          state: "MI",
          zip: "48219"
        }]
      end
    end

    seeder_class.new.seed

    assert_equal parent_ids.size * 4, Address.count
    assert_equal(
      parent_ids.index_with { 4 },
      Address.group(:user_id).count
    )
  ensure
    Address.delete_all
  end

  test "data_array delegates persistence and parent lookup to adapter" do
    adapter = FakeAdapter.new
    record = {
      slug: "first",
      name: "First"
    }
    Planter.config.adapter = adapter
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method(
        :data_array,
        model: "Widget",
        parent: :account,
        unique_columns: :slug
      )

      define_method(:data) { [record] }
    end

    seeder_class.new.seed

    assert_equal(
      [{
        model_name: "Widget",
        lookup_attributes: {slug: "first", account_id: 42},
        create_attributes: {name: "First"}
      }],
      adapter.created_records
    )
    assert_equal({slug: "first", name: "First"}, record)
  end

  test "data_array moves non-column lookup attributes into create attributes" do
    adapter = FakeColumnAdapter.new("Widget" => %w[slug name])
    Planter.config.adapter = adapter
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method :data_array, model: "Widget"

      def data
        [{
          slug: "first",
          name: "First",
          phone: "123-456-7890"
        }]
      end
    end

    assert_output(nil, /WARNING: Planter moved non-column lookup attributes for Widget into create attributes: phone/) do
      seeder_class.new.seed
    end

    assert_equal(
      [{
        model_name: "Widget",
        lookup_attributes: {slug: "first", name: "First"},
        create_attributes: {phone: "123-456-7890"}
      }],
      adapter.created_records
    )
  end

  test "unique_columns moves non-column lookup attributes into create attributes" do
    adapter = FakeColumnAdapter.new("Widget" => %w[slug name])
    Planter.config.adapter = adapter
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method(
        :data_array,
        model: "Widget",
        unique_columns: %i[slug external_id]
      )

      def data
        [{
          slug: "first",
          external_id: "external-first",
          name: "First"
        }]
      end
    end

    assert_output(nil, /WARNING: Planter moved non-column lookup attributes for Widget into create attributes: external_id/) do
      seeder_class.new.seed
    end

    assert_equal(
      [{
        model_name: "Widget",
        lookup_attributes: {slug: "first"},
        create_attributes: {external_id: "external-first", name: "First"}
      }],
      adapter.created_records
    )
  end

  test "parent seeding keeps native foreign key in lookup attributes" do
    adapter = FakeColumnAdapter.new("Widget" => %w[slug account_id])
    Planter.config.adapter = adapter
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method(
        :data_array,
        model: "Widget",
        parent: :account,
        unique_columns: :slug
      )

      def data
        [{
          slug: "first",
          name: "First"
        }]
      end
    end

    seeder_class.new.seed

    assert_equal(
      [{
        model_name: "Widget",
        lookup_attributes: {slug: "first", account_id: 42},
        create_attributes: {name: "First"}
      }],
      adapter.created_records
    )
  end

  test "non-column lookup warning is printed once for repeated fields" do
    adapter = FakeColumnAdapter.new("Widget" => %w[slug])
    Planter.config.adapter = adapter
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method :data_array, model: "Widget"

      def data
        [
          {slug: "first", phone: "123-456-7890"},
          {slug: "second", phone: "234-567-8901"}
        ]
      end
    end

    _stdout, stderr = capture_io { seeder_class.new.seed }

    assert_equal 1, stderr.scan("WARNING: Planter moved non-column lookup attributes").count
  end

  test "filtering raises when no native lookup attributes remain" do
    adapter = FakeColumnAdapter.new("Widget" => %w[slug])
    Planter.config.adapter = adapter
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method :data_array, model: "Widget"

      def data
        [{phone: "123-456-7890"}]
      end
    end
    error = nil

    _stdout, _stderr = capture_io do
      error = assert_raises(RuntimeError) { seeder_class.new.seed }
    end

    assert_equal(
      "No native lookup columns found for Widget. Add a native table column to the seed data or unique_columns.",
      error.message
    )
    assert_empty adapter.created_records
  end

  test "csv moves extra headers out of lookup attributes" do
    adapter = FakeColumnAdapter.new("Widget" => %w[email username])
    Planter.config.adapter = adapter
    seeder_class = Class.new(Planter::Seeder) do
      seeding_method :csv, model: "Widget", csv_name: :extra_users
    end

    assert_output(nil, /WARNING: Planter moved non-column lookup attributes for Widget into create attributes: phone/) do
      seeder_class.new.seed
    end

    assert_equal(
      [{
        model_name: "Widget",
        lookup_attributes: {email: "extra@example.com", username: "extra"},
        create_attributes: {phone: "123-456-7890"}
      }],
      adapter.created_records
    )
  end

  test "custom seed method" do
    Planter.seed
    assert_equal 2, Role.count
    User.all.each { |user| assert_equal 1, user.roles.count }
  end

  test "instance has access to class instance variables" do
    Planter::Seeder.seeding_method(
      :data_array,
      number_of_records: 5,
      model: "Address",
      parent: :user
    )
    seeder = Planter::Seeder.new
    assert_equal :data_array, seeder.seed_method
    assert_equal 5, seeder.number_of_records
    assert_equal "Address", seeder.model
    assert_equal :user, seeder.parent
  end

  private

  def reset_seeder_class_attributes
    Planter::Seeder.seed_method = nil
    Planter::Seeder.number_of_records = nil
    Planter::Seeder.model = nil
    Planter::Seeder.parent = nil
    Planter::Seeder.csv_name = nil
    Planter::Seeder.erb_trim_mode = nil
    Planter::Seeder.unique_columns = nil
  end

  class FakeAdapter
    attr_reader :created_records

    def initialize
      @created_records = []
    end

    def parent_ids(model_name:, parent:)
      raise "unexpected model" unless model_name == "Widget"
      raise "unexpected parent" unless parent == :account

      [42]
    end

    def foreign_key(model_name:, parent:)
      raise "unexpected model" unless model_name == "Widget"
      raise "unexpected parent" unless parent == :account

      :account_id
    end

    def create_record(model_name:, lookup_attributes:, create_attributes:)
      @created_records << {
        model_name: model_name,
        lookup_attributes: lookup_attributes,
        create_attributes: create_attributes
      }
    end
  end

  class FakeColumnAdapter < FakeAdapter
    def initialize(table_columns)
      super()
      @table_columns = table_columns
    end

    def table_columns(model_name:)
      @table_columns.fetch(model_name)
    end
  end
end
