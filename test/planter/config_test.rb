require "test_helper"

class Planter::ConfigTest < ActiveSupport::TestCase
  setup do
    @config = Planter::Config.new
  end

  test "sets default values" do
    assert_equal 'db/seeds', @config.seeders_directory
    assert_equal 'db/seed_files', @config.csv_files_directory
    assert_nil @config.tables
    assert_equal(false, @config.quiet)
  end

  test "attributes are accessible" do
    @config.seeders_directory = 'db/different_seeders_directory'
    assert_equal 'db/different_seeders_directory', @config.seeders_directory

    @config.csv_files_directory = 'db/different_csv_files_directory'
    assert_equal 'db/different_csv_files_directory', @config.csv_files_directory

    @config.tables = %i[users]
    assert_equal %i[users], @config.tables

    @config.quiet = true
    assert_equal true, @config.quiet
  end
end
