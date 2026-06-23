module Planter
  module Generators
    class SeederGenerator < Rails::Generators::Base
      argument :seeder, required: true

      desc "Creates a seeder file at #{::Planter.config.seeders_directory}"

      def generate_seeders
        (seeder == "ALL") ? tables.each { |t| generate(t) } : generate(seeder)
      end

      private

      def generate(seeder)
        empty_directory ::Planter.config.seeders_directory

        create_file "#{::Planter.config.seeders_directory}/#{seeder}_seeder.rb", <<~EOF
          class #{seeder.camelize}Seeder < Planter::Seeder
            # TODO: Choose a seeding_method. For example:
            # seeding_method :csv

            # For now, we overload the seed method so no exception will be raised.
            def seed
            end
          end
        EOF

        inject_into_file "config/initializers/planter.rb",
          "    #{seeder}\n",
          before: /^\s*\]\s*$/
      end

      def tables
        @tables ||= ::Planter.config.adapter.table_names
      end
    end
  end
end
