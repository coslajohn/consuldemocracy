module Segmentable
  extend ActiveSupport::Concern

  included do
    has_many :segmentations, as: :segmentable, dependent: :destroy
    has_many :segments, through: :segmentations

    # Scope for CanCanCan `accessible_by`
    # Returns items that have NO segments (public) OR match the user's segments
    scope :public_or_for_user_segments, ->(user_segment_ids = []) {
      if user_segment_ids.blank?
        # For guest users or users with no segments, only return public items
        left_outer_joins(:segmentations).where(segmentations: { id: nil })
      else
        # For users with segments, return public items + their segmented items
        left_outer_joins(:segmentations)
          .where("segmentations.id IS NULL OR segmentations.segment_id IN (?)", user_segment_ids)
          .distinct
      end
    }
  end

  # Is this record restricted to specific segments?
  def segment_restricted?
    segmentations.any?
  end

  # Is this record available to everyone?
  def public?
    !segment_restricted?
  end

  # Check if a specific user has access to this record
  def allows_participant?(user)
    return true if public?
    return false if user.nil?

    # Check if there is an intersection between the record's segments and the user's segments
    (segment_ids & user.segment_ids).any?
  end
end
