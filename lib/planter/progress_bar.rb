# frozen_string_literal: true

require "ruby-progressbar"

module Planter
  ##
  # Builds progress bars for seed runs.
  class ProgressBar
    ##
    # The format string used by visible progress bars.
    #
    # @return [String]
    FORMAT = "%t |%B| %p%% %c/%C"

    ##
    # Progress bar object used when visible progress bars are disabled.
    class NullProgressBar
      ##
      # No-op progress increment.
      def increment
      end
    end

    ##
    # Create a visible progress bar, or a null progress bar when disabled.
    #
    # @param [String] title progress bar title
    # @param [Integer] total total number of records to seed
    # @param [IO] output progress bar output stream
    #
    # @return [ProgressBar, NullProgressBar]
    def self.create(title:, total:, output: $stdout)
      return NullProgressBar.new unless enabled?(total)

      ::ProgressBar.create(
        title: title,
        total: total,
        output: output,
        format: FORMAT
      )
    end

    def self.enabled?(total)
      total.positive? && Planter.config.progress_bar && !Planter.config.quiet
    end
    private_class_method :enabled?
  end
end
