require "test_helper"

class PlanterTest < ActiveSupport::TestCase
  setup do
    Planter.reset_config
  end

  teardown do
    Planter.reset_config
  end

  test "it is configurable" do
    assert_instance_of Planter::Config, Planter.config

    assert_equal 'db/seeds', Planter.config.seeders_directory
    assert_equal 'db/seed_files', Planter.config.csv_files_directory
    assert_nil Planter.config.seeders
    refute Planter.config.quiet

    config = Planter.configure do |config|
      config.seeders_directory = "db/different_seeders_directory"
      config.csv_files_directory = "db/different_csv_files_directory"
      config.seeders = %i[users]
      config.quiet = true
    end

    assert_instance_of Planter::Config, config

    assert_equal 'db/different_seeders_directory', Planter.config.seeders_directory
    assert_equal 'db/different_csv_files_directory', Planter.config.csv_files_directory
    assert_equal %i[users], Planter.config.seeders
    assert Planter.config.quiet
  end

  test "it should seed" do
    Planter.configure do |config|
      config.seeders = %i[users addresses]
      config.quiet = true
    end
    Planter.seed

    assert_equal 2, User.count
    assert_equal 4, Address.count
  end
end
