module Admin
  module Segments
    class FormComponent < ApplicationComponent
      attr_reader :segment

      def initialize(segment:)
        @segment = segment
      end
    end
  end
end
