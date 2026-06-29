class CardLabel < ApplicationRecord
  belongs_to :card
  belongs_to :label

  validates :label_id, uniqueness: { scope: :card_id }
end
