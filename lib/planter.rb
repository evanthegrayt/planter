# frozen_string_literal: true

require 'csv'
require 'erb'
require 'planter/version'
require 'planter/railtie'
require 'planter/config'
require 'planter/seeder'

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
  # This is the method to call from your +db/seeds.rb+. It callse the seeders
  # listed in +Planter.config.seeders+. To call specific seeders at runtime,
  # you can set the +SEEDERS+ environmental variable to a comma-separated list
  # of seeders, like +rails db:seed SEEDERS=users,accounts+.
  #
  # @example
  #   # db/seeds.rb, assuming your +configure+ block is in an initializer.
  #   Planter.seed
  def seed
    seeders = ENV['SEEDERS']&.split(',') || config.seeders&.map(&:to_s)
    raise RuntimeError, 'No seeders specified' if seeders.blank?

    seeders.each do |s|
      require Rails.root.join(config.seeders_directory, "#{s}_seeder.rb").to_s
      puts "Seeding #{s}" unless config.quiet
      "#{s.camelize}Seeder".constantize.new.seed
    end
  end
end
