# Append-only audit log / activity feed for a board.
class Activity < ApplicationRecord
  belongs_to :board
  belongs_to :user, optional: true
  belongs_to :subject, polymorphic: true, optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
