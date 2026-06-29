class Comment < ApplicationRecord
  belongs_to :card
  belongs_to :user

  validates :body, presence: true, length: { maximum: 5_000 }

  scope :recent, -> { order(created_at: :desc) }
end
