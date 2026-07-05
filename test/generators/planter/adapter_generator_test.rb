require "test_helper"
require "rails/generators/test_case"
require "generators/planter/adapter_generator"

class Planter::Generators::AdapterGeneratorTest < Rails::Generators::TestCase
  tests Planter::Generators::AdapterGenerator
  destination File.expand_path("../../../tmp/generators/adapter", __dir__)
  setup :prepare_destination
  teardown { remove_generated_adapter_constant }

  test "creates an adapter with the expected interface" do
    write_initializer(default_initializer)

    run_generator ["sequel"]

    assert_file "lib/planter/adapters/sequel.rb" do |contents|
      assert_includes contents, "class Sequel"
      assert_includes contents, "def create_record(context:, lookup_attributes:, create_attributes:)"
      assert_includes contents, "def parent_ids(context:)"
      assert_includes contents, "def foreign_key(context:)"
      assert_includes contents, "def table_columns(context:)"
      assert_includes contents, "def table_names"
      assert_includes contents, "raise NotImplementedError"
    end
  end

  test "generated adapter methods raise until implemented" do
    write_initializer(default_initializer)

    run_generator ["sequel"]
    load File.join(destination_root, "lib/planter/adapters/sequel.rb")
    adapter = Planter::Adapters::Sequel.new

    assert_raises(NotImplementedError) do
      adapter.create_record(
        context: context,
        lookup_attributes: {},
        create_attributes: {}
      )
    end
    assert_raises(NotImplementedError) { adapter.parent_ids(context: context) }
    assert_raises(NotImplementedError) { adapter.foreign_key(context: context) }
    assert_raises(NotImplementedError) { adapter.table_columns(context: context) }
    assert_raises(NotImplementedError) { adapter.table_names }
  end

  test "replaces generated active record adapter configuration" do
    write_initializer(default_initializer)

    run_generator ["sequel"]

    assert_file "config/initializers/planter.rb" do |contents|
      assert_includes contents, "require 'planter'"
      assert_includes contents, "require Rails.root.join('lib/planter/adapters/sequel').to_s"
      assert_includes contents, "config.adapter = Planter::Adapters::Sequel.new"
      assert_includes contents, "config.seeders = %i["
      assert_not_includes contents, "require 'planter/adapters/active_record'"
      assert_not_includes contents, "Planter::Adapters::ActiveRecord.new"
    end
  end

  test "replaces adapter lines when they have moved" do
    write_initializer(<<~RUBY)
      require 'planter'

      Planter.configure do |config|
        config.seeders = %i[
          users
        ]

        config.adapter = Planter::Adapters::ActiveRecord.new
      end

      require "planter/adapters/active_record"
    RUBY

    run_generator ["mongoid"]

    assert_file "config/initializers/planter.rb" do |contents|
      assert_match(/^require Rails\.root\.join\('lib\/planter\/adapters\/mongoid'\)\.to_s$/, contents)
      assert_match(/^  config.adapter = Planter::Adapters::Mongoid.new$/, contents)
      assert_match(/^    users$/, contents)
      assert_no_match(/planter\/adapters\/active_record/, contents)
      assert_no_match(/Planter::Adapters::ActiveRecord\.new/, contents)
    end
  end

  test "inserts missing adapter lines without changing seeders" do
    write_initializer(<<~RUBY)
      require 'planter'

      Planter.configure do |config|
        config.seeders = %i[
          users
          addresses
        ]
      end
    RUBY

    run_generator ["sequel"]

    assert_file "config/initializers/planter.rb" do |contents|
      assert_match(
        /^require 'planter'\nrequire Rails\.root\.join\('lib\/planter\/adapters\/sequel'\)\.to_s$/,
        contents
      )
      assert_match(
        /^Planter\.configure do \|config\|\n  config.adapter = Planter::Adapters::Sequel.new$/,
        contents
      )
      assert_match(/^  config.seeders = %i\[$/, contents)
      assert_match(/^    users$/, contents)
      assert_match(/^    addresses$/, contents)
    end
  end

  private

  def context
    Planter::SeedContext.new(
      table_name: :users,
      seed_method: :data_array,
      csv_name: :users,
      parent: :account,
      number_of_records: 1,
      unique_columns: nil,
      erb_trim_mode: nil
    )
  end

  def default_initializer
    <<~RUBY
      require 'planter'
      require 'planter/adapters/active_record'

      Planter.configure do |config|
        config.adapter = Planter::Adapters::ActiveRecord.new
        config.seeders = %i[
        ]
      end
    RUBY
  end

  def write_initializer(contents)
    FileUtils.mkdir_p(File.join(destination_root, "config", "initializers"))
    File.write(
      File.join(destination_root, "config", "initializers", "planter.rb"),
      contents
    )
  end

  def remove_generated_adapter_constant
    Planter::Adapters.send(:remove_const, :Sequel) if defined?(Planter::Adapters::Sequel)
    Planter::Adapters.send(:remove_const, :Mongoid) if defined?(Planter::Adapters::Mongoid)
  end
end
