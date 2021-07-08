# frozen_string_literal: true

module Planter
  ##
  # Progress bar for enumerables.
  #
  # @example
  #   names = ['John', 'Billy', 'Steve']
  #   names.each_with_object(ProgressBar.new(names.size)) do |name, progress|
  #     progress.update
  #     # Do something with name
  #     progress.report
  #   end
  class ProgressBar
    ##
    # The size of the enumerable object. Set at initialization.
    #
    # @return [Integer]
    attr_reader :total

    ##
    # The number of records that have been completed.
    #
    # @return [Integer]
    attr_reader :number_completed

    ##
    # The message to print once progress is completed. Set at initialization.
    #
    # @return [String]
    attr_reader :complete_message

    ##
    # Create a new progress bar.
    #
    # @param [Integer] total
    #
    # @kwarg [String] complete_message
    def initialize(total, complete_message: nil)
      @total = total.to_i
      @number_completed = 0
      @complete_message = complete_message
    end

    ##
    # Increment the number completed.
    #
    # @kwarg [Integer] step (Default: 1)
    def update(step: 1)
      @number_completed += step.to_i
    end

    ##
    # Print the progress bar.
    def report
      print "\r#{progress_bar} #{number_completed}/#{total}"
      print " [\e[32m#{complete_message}\e[0m]" if print_complete_message?
      puts if finished?
    end

    private

    ##
    # The progress bar to be printed. Completed percentage is filled with +=+,
    # while uncomplete is filled with +-+.
    #
    # @return [String]
    def progress_bar # :nodoc:
      "[#{'=' * complete_section}#{'-' * incomplete_section}]"
    end

    ##
    # Number of +=+ to fill the bar with.
    #
    # @return [Integer]
    def complete_section # :nodoc:
      (percent_complete / 2.0).floor
    end

    ##
    # Number of +-+ to fill the bar with.
    #
    # @return [Integer]
    def incomplete_section # :nodoc:
      ((100 - percent_complete) / 2.0).ceil
    end

    ##
    # The percentage of the total records that have been iterated through.
    #
    # @return [Integer]
    def percent_complete # :nodoc:
      (number_completed * 1.0 / total * 1.0) * 100
    end

    ##
    # Should we print the completed message, if it exists?
    #
    # @return [Boolean]
    def print_complete_message? # :nodoc:
      complete_message && finished?
    end

    ##
    # Is the number of completed items equal to the total?
    #
    # @return [Boolean]
    def finished? # :nodoc:
      number_completed == total
    end
  end
end
