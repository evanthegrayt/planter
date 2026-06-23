require "test_helper"
require "rails/generators/test_case"
require "generators/planter/seeder_generator"

class Planter::Generators::SeederGeneratorTest < Rails::Generators::TestCase
  tests Planter::Generators::SeederGenerator
  destination File.expand_path("../../../tmp/generators/seeder", __dir__)
  setup :prepare_destination
  teardown { Planter.reset_config }

  test "creates a named seeder and registers it in the initializer" do
    write_initializer

    run_generator ["users"]

    assert_file "db/seeds/users_seeder.rb" do |contents|
      assert_includes contents, "class UsersSeeder < Planter::Seeder"
      assert_includes contents, "# seeding_method :csv"
      assert_includes contents, "def seed"
    end

    assert_file "config/initializers/planter.rb" do |contents|
      assert_match(/^    users$/, contents)
    end
  end

  test "ALL creates seeders for application tables but not rails metadata tables" do
    write_initializer

    run_generator ["ALL"]

    assert_file "db/seeds/users_seeder.rb"
    assert_file "db/seeds/roles_users_seeder.rb"
    assert_no_file "db/seeds/ar_internal_metadata_seeder.rb"
    assert_no_file "db/seeds/schema_migrations_seeder.rb"
  end

  test "ALL uses the configured adapter to find tables" do
    Planter.config.adapter = Class.new do
      def table_names
        %w[custom_widgets custom_accounts]
      end
    end.new
    write_initializer

    run_generator ["ALL"]

    assert_file "db/seeds/custom_widgets_seeder.rb"
    assert_file "db/seeds/custom_accounts_seeder.rb"
    assert_no_file "db/seeds/users_seeder.rb"
  end

  private

  def write_initializer
    FileUtils.mkdir_p(File.join(destination_root, "config", "initializers"))
    File.write(
      File.join(destination_root, "config", "initializers", "planter.rb"),
      <<~RUBY
        Planter.configure do |config|
          config.seeders = %i[
          ]
        end
      RUBY
    )
  end
end
