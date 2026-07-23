module Admin
  module Segments
    class ListComponent < ApplicationComponent
      attr_reader :segments

      def initialize(segments:)
        @segments = segments
      end

      def render?
        segments.any?
      end
    end
  end
end
