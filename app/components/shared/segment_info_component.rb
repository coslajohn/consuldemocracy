class Shared::SegmentInfoComponent < ApplicationComponent
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def render?
    record.respond_to?(:segments) && record.segments.any?
  end
end
