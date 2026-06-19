require "test_helper"

class Planter::SeederTest < ActiveSupport::TestCase
  setup do
    Planter.reset_config
    Planter.configure do |c|
      c.seeders = %i[users addresses bios roles comments]
      c.quiet = true
      c.erb_trim_mode = "<>"
    end
  end

  teardown do
    Planter.reset_config
  end

  test "it has seeding method constant" do
    assert_equal %i[csv data_array], Planter::Seeder::SEEDING_METHODS
  end

  test "attributes are protected" do
    assert_raise(NameError) { seeder.seed_method }
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
    assert_equal 20, Comment.last.upvotes
    assert_equal "This is a TEST 1", Comment.first.message
  end

  test "has_one data_array with model parent and association" do
    Planter.seed
    assert_equal 2, Profile.count
  end

  test "has_many data_array with unique parent does not mutate records" do
    Planter.seed
    assert_equal User.count, Address.count
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
end
