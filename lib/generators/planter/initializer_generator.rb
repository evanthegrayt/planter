module Planter
  module Generators
    class InitializerGenerator < Rails::Generators::Base
      desc 'Genrates an initializer for Planter at config/initializers/planter.rb'

      def create_initializer_file
        create_file 'config/initializers/planter.rb', <<~RUBY
          require 'planter'

          Planter.configure do |config|
            # The list of seeders. These files are stored in the
            # config.seeders_directory, which can be changed below. When a new
            # seeder is generated, it will be appended to the bottom of this
            # list. If the order is incorrect, you'll need to adjust it. Just
            # be sure to keep the ending bracket on its own line, or the
            # generator won't know where to put new elements.
            config.seeders = %i[
            ]

            # The directory where the seeder files are kept.
            # config.seeders_directory = 'db/seeds'

            # The directory where CSVs are kept.
            # config.csv_files_directory = 'db/seed_files'

            # Should all output be silenced when running the task? Also turns
            # off the progress bar!
            # config.quiet = false

            # Should a progress bar be displayed when running the task? This
            # will be overruled if the quiet option is true.
            # config.progress_bar = true
          end
        RUBY
      end
    end
  end
end
