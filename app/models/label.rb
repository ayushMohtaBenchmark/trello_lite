class Label < ApplicationRecord
  belongs_to :board
  has_many :card_labels, dependent: :destroy
  has_many :cards, through: :card_labels

  validates :name, presence: true, length: { maximum: 60 },
                   uniqueness: { scope: :board_id, case_sensitive: false }
  validates :color, format: { with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/, message: "must be a hex colour" }
end
