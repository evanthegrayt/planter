require 'rake'
require "test_helper"

class Planter::SeederTest < ActiveSupport::TestCase
  setup do
    Planter.reset_config
    Planter.configure do |c|
      c.seeders = %i[users addresses bios roles]
      c.quiet = true
    end
  end

  teardown do
    Planter.reset_config
  end

  test "it has seeding method constant" do
    assert_equal %i[standard_csv data_array], Planter::Seeder::SEEDING_METHODS
  end

  test "attributes are protected" do
    assert_raise(NameError) { seeder.seeding_method }
  end

  test "standard_csv" do
    Planter.seed
    assert_equal 2, User.count
  end

  test "has_one data_array with model parent_model and association" do
    Planter.seed
    assert_equal 2, Profile.count
  end

  test "has_many data_array with parent_model and number_of_records" do
    Planter.seed
    assert_equal 4, Address.count
  end

  test "custom seed method" do
    Planter.seed
    assert_equal 2, Role.count
    User.all.each { |user| assert_equal 1, user.roles.count }
  end

  test "instance has access to class instance variables" do
    Planter::Seeder.seeding_method(
      :standard_csv,
      number_of_records: 5,
      model: 'Address',
      parent_model: 'User',
      association: :addresses,
    )
    seeder = Planter::Seeder.new
    assert_equal :standard_csv, seeder.send(:seeding_method)
    assert_equal 5, seeder.send(:number_of_records)
    assert_equal 'Address', seeder.send(:model)
    assert_equal 'User', seeder.send(:parent_model)
    assert_equal :addresses, seeder.send(:association)
    refute_nil seeder.send(:csv_file)
    assert_nil seeder.send(:data)
  end
end
