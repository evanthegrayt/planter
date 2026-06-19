require "test_helper"
require "rails/generators/test_case"
require "generators/planter/initializer_generator"

class Planter::Generators::InitializerGeneratorTest < Rails::Generators::TestCase
  tests Planter::Generators::InitializerGenerator
  destination File.expand_path("../../../tmp/generators/initializer", __dir__)
  setup :prepare_destination

  test "creates a planter initializer with documented configuration" do
    run_generator

    assert_file "config/initializers/planter.rb" do |contents|
      assert_includes contents, "require 'planter'"
      assert_includes contents, "Planter.configure do |config|"
      assert_includes contents, "config.seeders = %i["
      assert_includes contents, "# config.seeders_directory = 'db/seeds'"
      assert_includes contents, "# config.csv_files_directory = 'db/seed_files'"
      assert_includes contents, "# config.erb_trim_mode = nil"
    end
  end
end
