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

        register_seeder(seeder)
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

      def register_seeder(seeder)
        contents = ::File.read(initializer_full_path)
        ::File.write(initializer_full_path, add_seeder_to_initializer(contents, seeder))
      end

      def add_seeder_to_initializer(contents, seeder)
        assignment = contents.match(seeders_assignment_pattern)
        unless assignment
          raise Thor::Error, "Could not find config.seeders = %i[...] in #{initializer_path}"
        end

        opening_bracket_index = assignment.end(0) - 1
        closing_bracket_index = closing_bracket_index_for(contents, opening_bracket_index)
        unless closing_bracket_index
          raise Thor::Error,
            "Could not find the closing bracket for config.seeders in #{initializer_path}"
        end

        insert_seeder(contents, seeder, assignment[1], opening_bracket_index, closing_bracket_index)
      end

      def insert_seeder(
        contents,
        seeder,
        assignment_indent,
        opening_bracket_index,
        closing_bracket_index
      )
        body = contents[(opening_bracket_index + 1)...closing_bracket_index]
        updated = contents.dup

        if body.include?("\n")
          insert_multiline_seeder(
            updated,
            contents,
            seeder,
            assignment_indent,
            body,
            closing_bracket_index
          )
        elsif body.strip.empty?
          updated.insert(closing_bracket_index, seeder)
        else
          updated.insert(closing_bracket_index, " #{seeder}")
        end

        updated
      end

      def insert_multiline_seeder(
        updated,
        contents,
        seeder,
        assignment_indent,
        body,
        closing_bracket_index
      )
        closing_line_start = contents.rindex("\n", closing_bracket_index) + 1
        closing_line_prefix = contents[closing_line_start...closing_bracket_index]

        if closing_line_prefix.match?(/\A[ \t]*\z/)
          updated.insert(closing_line_start, "#{seeder_indent(body, assignment_indent)}#{seeder}\n")
        else
          updated.insert(closing_bracket_index, " #{seeder}")
        end
      end

      def seeder_indent(body, assignment_indent)
        item_line = body.lines.find { |line| line.match?(/\S/) }
        indent = item_line&.match(/\A[ \t]*/).to_s
        indent.empty? ? "#{assignment_indent}  " : indent
      end

      def closing_bracket_index_for(contents, opening_bracket_index)
        depth = 1
        index = opening_bracket_index + 1

        while index < contents.length
          if contents[index] == "\\"
            index += 2
            next
          elsif contents[index] == "["
            depth += 1
          elsif contents[index] == "]"
            depth -= 1
            return index if depth.zero?
          end

          index += 1
        end
      end

      def seeders_assignment_pattern
        /^([ \t]*)config\.seeders\s*=\s*%i\[/
      end

      def initializer_path
        "config/initializers/planter.rb"
      end

      def initializer_full_path
        ::File.join(destination_root, initializer_path)
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
