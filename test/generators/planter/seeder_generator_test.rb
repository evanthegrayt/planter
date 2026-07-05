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

  test "registers a named seeder in a populated multiline seeders array" do
    write_initializer(<<~RUBY)
      Planter.configure do |config|
        config.seeders = %i[
          users
        ]
      end
    RUBY

    run_generator ["addresses"]

    assert_file "config/initializers/planter.rb" do |contents|
      assert_match(/^    users$/, contents)
      assert_match(/^    addresses$/, contents)
      assert_match(/^  \]$/, contents)
    end
  end

  test "registers a named seeder in an inline seeders array" do
    write_initializer(<<~RUBY)
      Planter.configure do |config|
        config.seeders = %i[users]
      end
    RUBY

    run_generator ["addresses"]

    assert_file "config/initializers/planter.rb" do |contents|
      assert_includes contents, "config.seeders = %i[users addresses]"
    end
  end

  test "csv seeding method creates a csv seeder and seed file with table headers" do
    write_initializer

    run_generator ["users", "--seeding-method=csv"]

    assert_file "db/seeds/users_seeder.rb" do |contents|
      assert_includes contents, "class UsersSeeder < Planter::Seeder"
      assert_includes contents, "  seeding_method :csv"
      assert_not_includes contents, "def seed"
    end

    assert_file "db/seed_files/users.csv" do |contents|
      assert_equal "id,email,username,created_at,updated_at\n", contents
    end
  end

  test "data array seeding method creates a data array seeder" do
    write_initializer

    run_generator ["users", "--seeding-method=data-array"]

    assert_file "db/seeds/users_seeder.rb" do |contents|
      assert_includes contents, "class UsersSeeder < Planter::Seeder"
      assert_includes contents, "  seeding_method :data_array"
      assert_includes contents, "  def data"
      assert_includes contents, "    ["
      assert_not_includes contents, "def seed"
    end

    assert_no_file "db/seed_files/users.csv"
  end

  test "custom seeding method creates a custom seed method" do
    write_initializer

    run_generator ["users", "--seeding-method=custom"]

    assert_file "db/seeds/users_seeder.rb" do |contents|
      assert_includes contents, "class UsersSeeder < Planter::Seeder"
      assert_includes contents, "  def seed"
      assert_not_includes contents, "seeding_method"
    end

    assert_no_file "db/seed_files/users.csv"
  end

  test "unknown seeding method raises a helpful error" do
    seeder_generator = generator(["users"], "seeding_method" => "json")

    error = assert_raises(Thor::Error) do
      seeder_generator.send(:selected_seeding_method)
    end

    assert_equal "Expected --seeding-method to be one of: csv, data-array, custom", error.message
  end

  test "ALL creates seeders for application tables but not rails metadata tables" do
    write_initializer

    run_generator ["ALL"]

    assert_file "db/seeds/users_seeder.rb"
    assert_file "db/seeds/roles_users_seeder.rb"
    assert_no_file "db/seeds/ar_internal_metadata_seeder.rb"
    assert_no_file "db/seeds/schema_migrations_seeder.rb"
  end

  test "ALL with csv seeding method creates seeders and csv files for application tables" do
    write_initializer

    run_generator ["ALL", "--seeding-method=csv"]

    assert_file "db/seeds/users_seeder.rb" do |contents|
      assert_includes contents, "  seeding_method :csv"
    end
    assert_file "db/seeds/roles_users_seeder.rb" do |contents|
      assert_includes contents, "  seeding_method :csv"
    end
    assert_file "db/seed_files/users.csv"
    assert_file "db/seed_files/roles_users.csv" do |contents|
      assert_equal "user_id,role_id\n", contents
    end
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

  def write_initializer(contents = nil)
    FileUtils.mkdir_p(File.join(destination_root, "config", "initializers"))
    File.write(
      File.join(destination_root, "config", "initializers", "planter.rb"),
      contents || <<~RUBY
        Planter.configure do |config|
          config.seeders = %i[
          ]
        end
      RUBY
    )
  end
end
