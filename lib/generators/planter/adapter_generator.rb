module Planter
  module Generators
    class AdapterGenerator < Rails::Generators::Base
      argument :adapter, required: true

      desc "Creates an adapter file at lib/planter/adapters"

      def generate_adapter
        create_file adapter_path, <<~RUBY
          # frozen_string_literal: true

          module Planter
            module Adapters
              ##
              # Custom adapter for Planter.
              class #{adapter_class_name}
                ##
                # Create a record unless one already exists.
                #
                # @param [String] model_name the model being seeded
                #
                # @param [Hash] lookup_attributes attributes used to find the record
                #
                # @param [Hash] create_attributes additional attributes used only when
                #   creating a new record
                #
                # @return [Object]
                def create_record(model_name:, lookup_attributes:, create_attributes:)
                  raise NotImplementedError, "\#{self.class} must implement #create_record"
                end

                ##
                # Return the parent ids to use when seeding child records.
                #
                # @param [String] model_name the model being seeded
                #
                # @param [String, Symbol] parent the parent association name
                #
                # @return [Array]
                def parent_ids(model_name:, parent:)
                  raise NotImplementedError, "\#{self.class} must implement #parent_ids"
                end

                ##
                # Return the foreign key used to assign a parent id on a child record.
                #
                # @param [String] model_name the model being seeded
                #
                # @param [String, Symbol] parent the parent association name
                #
                # @return [String, Symbol]
                def foreign_key(model_name:, parent:)
                  raise NotImplementedError, "\#{self.class} must implement #foreign_key"
                end

                ##
                # Return native columns or fields for the model being seeded.
                #
                # @param [String] model_name the model being seeded
                #
                # @return [Array<String>]
                def table_columns(model_name:)
                  raise NotImplementedError, "\#{self.class} must implement #table_columns"
                end

                ##
                # Return table or collection names that can have seeders generated.
                #
                # @return [Array<String>]
                def table_names
                  raise NotImplementedError, "\#{self.class} must implement #table_names"
                end
              end
            end
          end
        RUBY
      end

      def update_initializer
        contents = ::File.read(initializer_full_path)
        contents = replace_or_insert_adapter_require(contents)
        contents = replace_or_insert_adapter_config(contents)

        ::File.write(initializer_full_path, contents)
      end

      private

      def adapter_path
        "lib/planter/adapters/#{adapter_file_name}.rb"
      end

      def adapter_file_name
        adapter.underscore
      end

      def adapter_class_name
        adapter.camelize
      end

      def adapter_require_line
        "require Rails.root.join('lib/planter/adapters/#{adapter_file_name}').to_s"
      end

      def adapter_config_line
        "config.adapter = Planter::Adapters::#{adapter_class_name}.new"
      end

      def initializer_path
        "config/initializers/planter.rb"
      end

      def initializer_full_path
        ::File.join(destination_root, initializer_path)
      end

      def replace_or_insert_adapter_require(contents)
        if contents.match?(adapter_require_pattern)
          contents.sub(adapter_require_pattern, adapter_require_line)
        else
          contents.sub(planter_require_pattern) { |line| "#{line.chomp}\n#{adapter_require_line}\n" }
        end
      end

      def replace_or_insert_adapter_config(contents)
        if contents.match?(adapter_config_pattern)
          contents.sub(adapter_config_pattern) { "#{$1}#{adapter_config_line}" }
        else
          contents.sub(configure_pattern) { |line| "#{line}\n#{$1}  #{adapter_config_line}" }
        end
      end

      def adapter_require_pattern
        /^[ \t]*require ["']planter\/adapters\/[^"']+["'][ \t]*$/
      end

      def planter_require_pattern
        /^[ \t]*require ["']planter["'][ \t]*\n?/
      end

      def adapter_config_pattern
        /^([ \t]*)config\.adapter\s*=.*$/
      end

      def configure_pattern
        /^([ \t]*)Planter\.configure do \|config\|[ \t]*$/
      end
    end
  end
end
