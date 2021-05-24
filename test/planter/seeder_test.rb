require 'rake'
require 'test_helper'

class Planter::SeederTest < ActiveSupport::TestCase
  setup do
    Planter.reset_config
    Planter.configure do |c|
      c.seeders = %i[users addresses bios roles comments]
      c.quiet = true
    end
  end

  teardown do
    Planter.reset_config
  end

  test 'it has seeding method constant' do
    assert_equal %i[csv data_array], Planter::Seeder::SEEDING_METHODS
  end

  test 'attributes are protected' do
    assert_raise(NameError) { seeder.seeding_method }
  end

  test 'csv' do
    Planter.seed
    assert_equal 2, User.count
    assert_equal 'test1@example.com', User.first.email
    assert_equal 'test2', User.last.username
  end

  test 'csv erb with parent_model' do
    Planter.seed
    # assert_equal 4, Comment.count
    assert_equal 20, Comment.last.upvotes
    assert_equal 'This is a test 1', Comment.first.message
  end

  test 'has_one data_array with model parent_model and association' do
    Planter.seed
    assert_equal 2, Profile.count
  end

  test 'has_many data_array with parent_model and number_of_records' do
    Planter.seed
    assert_equal 4, Address.count
  end

  test 'custom seed method' do
    Planter.seed
    assert_equal 2, Role.count
    User.all.each { |user| assert_equal 1, user.roles.count }
  end

  test 'instance has access to class instance variables' do
    Planter::Seeder.seeding_method(
      :data_array,
      number_of_records: 5,
      model: 'Address',
      parent_model: 'User',
      association: :addresses,
    )
    seeder = Planter::Seeder.new
    assert_equal :data_array, seeder.send(:seeding_method)
    assert_equal 5, seeder.send(:number_of_records)
    assert_equal 'Address', seeder.send(:model)
    assert_equal 'User', seeder.send(:parent_model)
    assert_equal :addresses, seeder.send(:association)
  end
end
