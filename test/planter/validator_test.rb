require "test_helper"
require "fileutils"
require "rake"

class Planter::ValidatorTest < ActiveSupport::TestCase
  setup do
    @original_seeders = ENV.delete("SEEDERS")
    @tmp_relative = File.join("tmp", "planter_validator", name.gsub(/\W/, "_"))
    @tmp = Rails.root.join(@tmp_relative)
    @seeders_relative = File.join(@tmp_relative, "seeds")
    @csv_relative = File.join(@tmp_relative, "seed_files")
    @seeders_dir = Rails.root.join(@seeders_relative)
    @csv_dir = Rails.root.join(@csv_relative)
    @constants = []

    FileUtils.rm_rf(@tmp)
    FileUtils.mkdir_p(@seeders_dir)
    FileUtils.mkdir_p(@csv_dir)

    Planter.reset_config
    Planter.configure do |config|
      config.seeders_directory = @seeders_relative
      config.csv_files_directory = @csv_relative
      config.adapter = FakeValidatorAdapter.new("widgets" => %w[email username slug])
    end
  end

  teardown do
    @constants.each do |constant|
      Object.send(:remove_const, constant.to_sym) if Object.const_defined?(constant, false)
    end
    FileUtils.rm_rf(@tmp)
    Planter.reset_config
    ENV["SEEDERS"] = @original_seeders
  end

  test "validates a csv seeder with a matching csv file" do
    write_seeder :valid_csv, <<~RUBY
      class ValidCsvSeeder < Planter::Seeder
        seeding_method :csv, table: :widgets
      end
    RUBY
    write_csv "widgets.csv", "email,username\none@example.com,one\n"
    Planter.config.seeders = %i[valid_csv]

    result = Planter.validate

    assert result.success?
    assert_empty result.errors
    assert_empty result.warnings
    assert_empty Planter.config.adapter.created_records
    refute Planter.config.adapter.parent_ids_called
  end

  test "does not execute csv transformations during validation" do
    write_seeder :csv_transformations, <<~RUBY
      class CsvTransformationsSeeder < Planter::Seeder
        seeding_method :csv, table: :widgets

        def transformations
          raise "validation should not call transformations"
        end
      end
    RUBY
    write_csv "widgets.csv", "email\none@example.com\n"
    Planter.config.seeders = %i[csv_transformations]

    assert Planter.validate.success?
  end

  test "validates a data array seeder with data" do
    write_seeder :valid_data, <<~RUBY
      class ValidDataSeeder < Planter::Seeder
        seeding_method :data_array, table: :widgets

        def data
          [{slug: "one"}]
        end
      end
    RUBY
    Planter.config.seeders = %i[valid_data]

    assert Planter.validate.success?
  end

  test "does not execute parent lookups during validation" do
    write_seeder :parent_data, <<~RUBY
      class ParentDataSeeder < Planter::Seeder
        seeding_method :data_array, table: :widgets, parent: :account

        def data
          [{slug: "one"}]
        end
      end
    RUBY
    Planter.config.seeders = %i[parent_data]

    result = Planter.validate

    assert result.success?
    refute Planter.config.adapter.parent_ids_called
  end

  test "allows a custom seeder that overrides seed" do
    write_seeder :custom_only, <<~RUBY
      class CustomOnlySeeder < Planter::Seeder
        def seed
          raise "validation should not call seed"
        end
      end
    RUBY
    Planter.config.seeders = %i[custom_only]

    result = Planter.validate

    assert result.success?
    assert_empty result.errors
  end

  test "SEEDERS validates only requested seeders" do
    write_seeder :requested_data, <<~RUBY
      class RequestedDataSeeder < Planter::Seeder
        seeding_method :data_array, table: :widgets

        def data
          []
        end
      end
    RUBY
    Planter.config.seeders = %i[missing_from_config requested_data]
    ENV["SEEDERS"] = "requested_data"

    result = Planter.validate

    assert result.success?
    assert_empty result.errors
  end

  test "fails when no seeders are configured" do
    Planter.config.seeders = nil

    result = Planter.validate

    refute result.success?
    assert_includes result.errors.first, "No seeders configured"
  end

  test "fails when a seeder file is missing" do
    Planter.config.seeders = %i[missing_file]

    result = Planter.validate

    refute result.success?
    assert_match(/Seeder file not found for missing_file/, result.errors.join("\n"))
  end

  test "fails when a seeder class is missing" do
    write_seeder :missing_class, <<~RUBY
      class DifferentSeeder < Planter::Seeder
        def seed
        end
      end
    RUBY
    Planter.config.seeders = %i[missing_class]

    result = Planter.validate

    refute result.success?
    assert_includes(
      result.errors,
      "Seeder class MissingClassSeeder could not be constantized."
    )
  end

  test "fails when a default seeder has no seeding method" do
    write_seeder :no_method, <<~RUBY
      class NoMethodSeeder < Planter::Seeder
      end
    RUBY
    Planter.config.seeders = %i[no_method]

    result = Planter.validate

    refute result.success?
    assert_includes result.errors, "NoMethodSeeder must define a valid seeding_method."
  end

  test "fails when a default seeder has an invalid seeding method" do
    write_seeder :invalid_method, <<~RUBY
      class InvalidMethodSeeder < Planter::Seeder
        self.seed_method = :json
      end
    RUBY
    Planter.config.seeders = %i[invalid_method]

    result = Planter.validate

    refute result.success?
    assert_includes(
      result.errors,
      "InvalidMethodSeeder must define a valid seeding_method."
    )
  end

  test "fails when a csv seeder has no matching csv file" do
    write_seeder :missing_csv, <<~RUBY
      class MissingCsvSeeder < Planter::Seeder
        seeding_method :csv, table: :widgets, csv_name: :missing_widgets
      end
    RUBY
    Planter.config.seeders = %i[missing_csv]

    result = Planter.validate

    refute result.success?
    assert_includes result.errors, "CSV seed file not found for widgets."
  end

  test "fails when the adapter is missing required API" do
    write_seeder :adapter_custom, <<~RUBY
      class AdapterCustomSeeder < Planter::Seeder
        def seed
        end
      end
    RUBY
    Planter.config.seeders = %i[adapter_custom]
    Planter.config.adapter = Object.new

    result = Planter.validate

    refute result.success?
    assert_includes result.errors, "Configured adapter must respond to #create_record."
    assert_includes result.errors, "Configured adapter must respond to #parent_ids."
    assert_includes result.errors, "Configured adapter must respond to #foreign_key."
    assert_includes result.errors, "Configured adapter must respond to #table_columns."
    assert_includes result.errors, "Configured adapter must respond to #table_names."
  end

  test "fails when csv headers have no native lookup columns" do
    write_seeder :no_native_csv, <<~RUBY
      class NoNativeCsvSeeder < Planter::Seeder
        seeding_method :csv, table: :widgets
      end
    RUBY
    write_csv "widgets.csv", "phone\n123-456-7890\n"
    Planter.config.seeders = %i[no_native_csv]

    result = Planter.validate

    refute result.success?
    assert_includes(
      result.errors,
      "No native lookup columns found for widgets. " \
        "Add a native table column to the seed data or unique_columns."
    )
  end

  test "warns when csv headers include non-column lookup attributes" do
    write_seeder :extra_header_csv, <<~RUBY
      class ExtraHeaderCsvSeeder < Planter::Seeder
        seeding_method :csv, table: :widgets
      end
    RUBY
    write_csv "widgets.csv", "email,phone\none@example.com,123-456-7890\n"
    Planter.config.seeders = %i[extra_header_csv]

    result = Planter.validate

    assert result.success?
    assert_empty result.errors
    assert_includes(
      result.warnings,
      "Planter will move non-column lookup attributes for widgets " \
        "into create attributes: phone."
    )
  end

  private

  def write_seeder(name, contents)
    File.write(@seeders_dir.join("#{name}_seeder.rb"), contents)
    @constants << "#{name.to_s.camelize}Seeder"
  end

  def write_csv(name, contents)
    File.write(@csv_dir.join(name), contents)
  end

  class FakeValidatorAdapter
    attr_reader :created_records
    attr_reader :parent_ids_called

    def initialize(table_columns)
      @table_columns = table_columns
      @created_records = []
      @parent_ids_called = false
    end

    def create_record(context:, lookup_attributes:, create_attributes:)
      @created_records << {
        context: context,
        lookup_attributes: lookup_attributes,
        create_attributes: create_attributes
      }
    end

    def parent_ids(context:)
      @parent_ids_called = true
      [1]
    end

    def foreign_key(context:)
      :parent_id
    end

    def table_columns(context:)
      @table_columns.fetch(context.table_name, [])
    end

    def table_names
      @table_columns.keys
    end
  end
end

class PlanterValidateTaskTest < ActiveSupport::TestCase
  setup do
    @original_env = {
      "SEEDERS" => ENV.delete("SEEDERS"),
      "SEEDERS_DIRECTORY" => ENV.delete("SEEDERS_DIRECTORY"),
      "CSV_FILES_DIRECTORY" => ENV.delete("CSV_FILES_DIRECTORY")
    }
    @tmp_relative = File.join("tmp", "planter_validate_task", name.gsub(/\W/, "_"))
    @tmp = Rails.root.join(@tmp_relative)
    @seeders_relative = File.join(@tmp_relative, "seeds")
    @csv_relative = File.join(@tmp_relative, "seed_files")
    @seeders_dir = Rails.root.join(@seeders_relative)
    @csv_dir = Rails.root.join(@csv_relative)
    @old_rake_application = Rake.application

    FileUtils.rm_rf(@tmp)
    FileUtils.mkdir_p(@seeders_dir)
    FileUtils.mkdir_p(@csv_dir)

    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load Rails.root.join("..", "..", "lib", "tasks", "planter_tasks.rake")

    Planter.reset_config
    Planter.configure do |config|
      config.seeders = %i[task_csv]
      config.adapter = Planter::ValidatorTest::FakeValidatorAdapter.new(
        "widgets" => %w[email]
      )
    end
  end

  teardown do
    if Object.const_defined?(:TaskCsvSeeder, false)
      Object.send(:remove_const, :TaskCsvSeeder)
    end
    FileUtils.rm_rf(@tmp)
    Planter.reset_config
    Rake.application = @old_rake_application
    @original_env.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  test "planter validate task prints success and applies directory overrides" do
    File.write(
      @seeders_dir.join("task_csv_seeder.rb"),
      <<~RUBY
        class TaskCsvSeeder < Planter::Seeder
          seeding_method :csv, table: :widgets
        end
      RUBY
    )
    File.write(@csv_dir.join("widgets.csv"), "email\none@example.com\n")
    ENV["SEEDERS_DIRECTORY"] = @seeders_relative
    ENV["CSV_FILES_DIRECTORY"] = @csv_relative

    stdout, stderr = capture_io { Rake::Task["planter:validate"].invoke }

    assert_match(/Planter validation passed\./, stdout)
    assert_empty stderr
  end

  test "planter validate task exits non-zero on fatal errors" do
    error = nil

    stdout, stderr = capture_io do
      error = assert_raises(SystemExit) { Rake::Task["planter:validate"].invoke }
    end

    assert_equal 1, error.status
    assert_empty stdout
    assert_match(/ERROR: Seeder file not found for task_csv/, stderr)
    assert_match(/Planter validation failed\./, stderr)
  end
end
