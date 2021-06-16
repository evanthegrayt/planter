# frozen_string_literal: true

require 'forwardable'

module Planter
  class Seeder
    ##
    # Abstracts arrays of record hashes into an enumerable.
    class RecordList
      include Enumerable
      extend Forwardable

      attr_reader :data

      def_delegators :@data, :<<, :each

      def initialize(data)
        @data = data
      end

      def each_with_progress(&block)
        each_with_object(progress_bar) do |array, progress|
          progress.update
          block.call(array)
          progress.report
        end
      end

      private

      def progress_bar
        @progress_bar ||= ::Planter::ProgressBar.new(
          count,
          complete_message: 'Successfully Seeded'
        )
      end
    end
  end
end
