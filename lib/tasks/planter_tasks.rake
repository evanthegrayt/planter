require 'planter'

namespace :planter do
  desc 'Seed application. Use this to keep planter separate from db:seed'
  task seed: :environment do
    Planter.configure do |config|
      # NOTE: the seed method already looks for ENV['SEEDERS']
      ENV['SEEDERS_DIRECTORY'] && config.seeders_directory = ENV['SEEDERS_DIRECTORY']
      ENV['CSV_FILES_DIRECTORY'] && config.csv_files_directory = ENV['CSV_FILES_DIRECTORY']
    end
    Planter.seed
  end
end
