# frozen_string_literal: true

require "csv"
require "erb"
require "planter/version"
require "planter/railtie"
require "planter/config"
require "planter/seed_context"
require "planter/csv_data_source"
require "planter/record_attributes"
require "planter/seeder"
require "planter/validator"

##
# The main module for the plugin. It nicely wraps the +Planter::Config+ class
# so that you can customize the plugin via an initializer or in the
# +db/seeds.rb+ file. This is how you'll specify your list of seeders to use,
# along with customizing the +seeders_directory+ and +csv_files_directory+.
#
#   Planter.configure do |config|
#     config.seeders = %i[users]
#     config.seeders_directory = 'db/seeds'
#     config.csv_files_directory = 'db/seed_files'
#   end
#
# To then seed your application, simply call the +seed+ method from your
# +db/seeds.rb+ file (or wherever you need to call it from).
#
#   Planter.seed
module Planter
  module_function

  ##
  # The seeder configuration.
  #
  # @return [Planter::Config]
  def config
    @config ||= Planter::Config.new
  end

  ##
  # Resets the config back to its initial state.
  #
  # @return [Planter::Config]
  def reset_config
    @config = Planter::Config.new
  end

  ##
  # Quick way of configuring the directories via an initializer.
  #
  # @return [Planter::Config]
  #
  # @example
  #   require 'planter'
  #   Planter.configure do |config|
  #     config.seeders = %i[users]
  #     config.seeders_directory = 'db/seeds'
  #     config.csv_files_directory = 'db/seed_files'
  #   end
  def configure
    config.tap { |c| yield c }
  end

  ##
  # This is the method to call from your +db/seeds.rb+. It calls the seeders
  # listed in +Planter.config.seeders+. To call specific seeders at runtime,
  # you can set the +SEEDERS+ environment variable to a comma-separated list
  # of seeders, like +rails db:seed SEEDERS=users,accounts+.
  #
  # @example
  #   # db/seeds.rb, assuming your +configure+ block is in an initializer.
  #   Planter.seed
  def seed
    seeders = ENV["SEEDERS"]&.split(",") || config.seeders&.map(&:to_s)
    if seeders.blank?
      warn "WARNING: Planter.seed was called, but no seeders were specified. Add seeders to config.seeders in config/initializers/planter.rb or set SEEDERS."
      return
    end

    seeders.each do |s|
      require Rails.root.join(config.seeders_directory, "#{s}_seeder.rb").to_s
      puts "Seeding #{s}" unless config.quiet
      "#{s.camelize}Seeder".constantize.new.seed
    end
  end

  ##
  # Validate the configured seed plan without creating records. This checks
  # seeder files, seeder classes, built-in seeding method configuration, CSV
  # headers where possible, and the configured adapter API.
  #
  # @return [Planter::Validator::Result]
  def validate
    Planter::Validator.new.validate
  end
end
