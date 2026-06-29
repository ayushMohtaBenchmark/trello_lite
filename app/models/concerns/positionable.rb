# Gives a model an integer `position` scoped to a sibling set. New records are
# appended to the end of their scope; reordering is handled by service objects.
module Positionable
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order(:position, :id) }
    before_create :assign_default_position
  end

  # Models including this concern must declare the sibling scope, e.g.
  #   def positioning_scope = { list_id: list_id }
  def positioning_scope
    raise NotImplementedError, "#{self.class} must define #positioning_scope"
  end

  def assign_default_position
    return if position.present? && position.positive?

    self.position = (self.class.where(positioning_scope).maximum(:position) || 0) + 1
  end
end
