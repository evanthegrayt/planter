module Planter
  ##
  # Namespace for Rails generators provided by Planter.
  module Generators
    ##
    # Rails generator that creates Planter's initializer.
    class InitializerGenerator < Rails::Generators::Base
      desc "Generates an initializer for Planter at config/initializers/planter.rb"

      ##
      # Create the default Planter initializer file.
      def create_initializer_file
        create_file "config/initializers/planter.rb", <<~EOF
          require 'planter'
          require 'planter/adapters/active_record'

          Planter.configure do |config|
            ##
            # The adapter used to create records, discover parent records, and
            # inspect database table names. Active Record is used by default.
            # To use a custom adapter, replace this line with your own adapter.
            config.adapter = Planter::Adapters::ActiveRecord.new

            ##
            # The list of seeders. These files are stored in the
            # config.seeders_directory, which can be changed below. When a new
            # seeder is generated, it will be appended to the bottom of this
            # list. If the order is incorrect, you'll need to adjust it.
            # The generator can append to either multiline or inline %i[...]
            # arrays.
            config.seeders = %i[
            ]

            ##
            # The directory where the seeders are kept.
            config.seeders_directory = 'db/seeds'

            ##
            # The directory where CSVs are kept.
            config.csv_files_directory = 'db/seed_files'

            ##
            # When true, don't print output when seeding.
            config.quiet = false

            ##
            # When false, don't print progress bars while seeding.
            # This is ignored when config.quiet is true.
            config.progress_bar = true

            ##
            # The default trim mode for ERB. Valid modes are:
            # '%'  enables Ruby code processing for lines beginning with %
            # '<>' omit newline for lines starting with <% and ending in %>
            # '>'  omit newline for lines ending in %>
            # '-'  omit blank lines ending in -%>
            # I recommend reading the help documentation for ERB::new()
            config.erb_trim_mode = nil
          end
        EOF
      end
    end
  end
end
