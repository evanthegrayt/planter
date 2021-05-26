module Planter
  module Generators
    class InitializerGenerator < Rails::Generators::Base
      desc 'Genrates an initializer for Planter at config/initializers/planter.rb'

      def create_initializer_file
        create_file 'config/initializers/planter.rb', <<~EOF
          require 'planter'

          Planter.configure do |config|
            ##
            # The list of seeders. These files are stored in the
            # config.seeders_directory, which can be changed below. When a new
            # seeeder is generated, it will be appended to the bottom of this
            # list. If the order is incorrect, you'll need to adjust the it.
            # Just be sure to keep the ending bracket on its own line, or the
            # generator won't know where to put new elements.
            config.seeders = %i[
            ]

            ##
            # The directory where the seeder files are kept.
            # config.seeders_directory = 'db/seeds'

            ##
            # The directory where CSVs are kept.
            # config.csv_files_directory = 'db/seed_files'
          end
        EOF
      end
    end
  end
end
