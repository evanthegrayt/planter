require 'test_helper'

class Planter::SeederTest < ActiveSupport::TestCase
  setup do
    Planter.reset_config
    Planter.configure do |c|
      c.seeders = %i[users addresses bios roles comments]
      c.quiet = true
      c.erb_trim_mode = '<>'
    end
  end

  teardown do
    Planter.reset_config
  end

  test 'it has seeding method constant' do
    assert_equal %i[csv data_array], Planter::Seeder::SEEDING_METHODS
  end

  test 'attributes are protected' do
    assert_raise(NameError) { seeder.seed_method }
  end

  test 'csv with unique columns' do
    Planter.seed
    assert_equal 2, User.count
    assert_equal 'test1@example.com', User.first.email
    assert_equal 'test2', User.last.username
  end

  test 'csv erb with parent' do
    Planter.seed
    assert_equal 4, Comment.count
    assert_equal 20, Comment.last.upvotes
    assert_equal 'This is a test 1', Comment.first.message
  end

  test 'has_one data_array with model parent and association' do
    Planter.seed
    assert_equal 2, Profile.count
  end

  test 'has_many data_array with unique parent and number_of_records' do
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
      parent: :user,
    )
    seeder = Planter::Seeder.new
    assert_equal :data_array, seeder.seed_method
    assert_equal 5, seeder.number_of_records
    assert_equal 'Address', seeder.model
    assert_equal :user, seeder.parent
  end
end
