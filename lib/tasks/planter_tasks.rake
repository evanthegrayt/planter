require "planter"

namespace :planter do
  apply_directory_overrides = lambda do
    if ENV["SEEDERS_DIRECTORY"]
      Planter.config.seeders_directory = ENV["SEEDERS_DIRECTORY"]
    end

    if ENV["CSV_FILES_DIRECTORY"]
      Planter.config.csv_files_directory = ENV["CSV_FILES_DIRECTORY"]
    end
  end

  desc "Seed application. Use this to keep planter separate from db:seed"
  task seed: :environment do
    # NOTE: the seed method already looks for ENV['SEEDERS']
    apply_directory_overrides.call
    Planter.seed
  end

  desc "Validate Planter configuration without creating records"
  task validate: :environment do
    apply_directory_overrides.call
    result = Planter.validate

    result.warnings.each { |warning| warn "WARNING: #{warning}" }
    result.errors.each { |error| warn "ERROR: #{error}" }

    if result.success?
      puts(
        result.warnings.empty? ?
          "Planter validation passed." :
          "Planter validation completed with warnings."
      )
    else
      abort "Planter validation failed."
    end
  end
end
