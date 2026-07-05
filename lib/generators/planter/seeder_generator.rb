module Planter
  ##
  # Namespace for Rails generators provided by Planter.
  module Generators
    ##
    # Rails generator that creates one or more Planter seeder files.
    #
    # By default, generated seeders include a TODO comment and an empty +seed+
    # method so they do not raise until a seeding method is chosen. Pass
    # +--seeding-method=csv+, +--seeding-method=data-array+, or
    # +--seeding-method=custom+ to generate a seeder for a specific style. The
    # +csv+ method also creates a CSV seed file with headers pulled from the
    # table being seeded.
    class SeederGenerator < Rails::Generators::Base
      ##
      # Generator-supported seeding method templates.
      #
      # @return [Array<Symbol>]
      SEEDING_METHODS = %i[csv data_array custom].freeze

      argument :seeder, required: true

      class_option :seeding_method,
        type: :string,
        desc: "Generate a seeder for a specific method: csv, data-array, or custom"

      desc "Creates a seeder file at #{::Planter.config.seeders_directory}"

      ##
      # Generate the requested seeder, or generate a seeder for every table
      # when the argument is +ALL+.
      def generate_seeders
        (seeder == "ALL") ? tables.each { |t| generate(t) } : generate(seeder)
      end

      private

      def generate(seeder)
        empty_directory ::Planter.config.seeders_directory

        create_file(
          "#{::Planter.config.seeders_directory}/#{seeder}_seeder.rb",
          [
            "class #{seeder.camelize}Seeder < Planter::Seeder",
            indent(seeder_contents),
            "end",
            ""
          ].join("\n")
        )

        create_csv(seeder) if selected_seeding_method == :csv

        inject_into_file "config/initializers/planter.rb",
          "    #{seeder}\n",
          before: /^\s*\]\s*$/
      end

      def seeder_contents
        case selected_seeding_method
        when :csv
          "seeding_method :csv"
        when :data_array
          <<~RUBY.rstrip
            seeding_method :data_array

            def data
              [
              ]
            end
          RUBY
        when :custom
          custom_seed_contents
        else
          [
            "# TODO: Choose a seeding_method. For example:",
            "# seeding_method :csv",
            "",
            "# For now, we override the seed method so no exception will be raised.",
            custom_seed_contents
          ].join("\n")
        end
      end

      def custom_seed_contents
        <<~RUBY.rstrip
          def seed
          end
        RUBY
      end

      def indent(contents)
        contents.lines.map do |line|
          line.strip.empty? ? line : "  #{line}"
        end.join
      end

      def selected_seeding_method
        return unless options["seeding_method"]

        method = options["seeding_method"].tr("-", "_").to_sym
        unless SEEDING_METHODS.include?(method)
          raise Thor::Error, "Expected --seeding-method to be one of: csv, data-array, custom"
        end

        method
      end

      def create_csv(seeder)
        empty_directory ::Planter.config.csv_files_directory

        create_file(
          "#{::Planter.config.csv_files_directory}/#{seeder}.csv",
          "#{csv_headers(seeder).join(",")}\n"
        )
      end

      def csv_headers(seeder)
        ::Planter.config.adapter.table_columns(context: csv_context(seeder))
      end

      def csv_context(seeder)
        ::Planter::SeedContext.new(
          table_name: seeder,
          seed_method: :csv,
          csv_name: seeder,
          parent: nil,
          number_of_records: 1,
          unique_columns: nil,
          erb_trim_mode: ::Planter.config.erb_trim_mode
        )
      end

      def tables
        @tables ||= ::Planter.config.adapter.table_names
      end
    end
  end
end
