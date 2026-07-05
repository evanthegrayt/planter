# frozen_string_literal: true

require "ruby-progressbar"

module Planter
  ##
  # Builds progress bars for seed runs.
  class ProgressBar
    FORMAT = "%t |%B| %p%% %c/%C"

    class NullProgressBar
      def increment
      end
    end

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
