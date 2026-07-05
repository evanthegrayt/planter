# frozen_string_literal: true

module Planter
  ##
  # Loads CSV seed data for a configured seeder.
  class CsvDataSource
    ##
    # Create a CSV data source.
    #
    # @param [Planter::SeedContext] context seeder configuration
    #
    # @param [Planter::Seeder] seeder seeder instance used for ERB binding
    def initialize(context:, seeder:)
      @context = context
      @seeder = seeder
    end

    ##
    # Return parsed CSV rows as hashes.
    #
    # @return [Array<Hash>]
    def data
      contents = ::File.read(path)
      if path.include?(".erb")
        contents = ERB.new(contents, trim_mode: context.erb_trim_mode).result(seeder_binding)
      end

      ::CSV.parse(
        contents,
        headers: true,
        header_converters: :symbol
      ).map(&:to_hash)
    end

    ##
    # Return the first matching CSV path for the configured CSV name.
    #
    # @return [String, nil]
    def path
      @path ||=
        %W[#{context.csv_name}.csv #{context.csv_name}.csv.erb #{context.csv_name}.erb.csv]
          .map { |file| Rails.root.join(Planter.config.csv_files_directory, file).to_s }
          .find { |file| ::File.file?(file) }
    end

    private

    attr_reader :context, :seeder

    def seeder_binding
      seeder.instance_eval { binding }
    end
  end
end
