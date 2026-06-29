class CardAssignment < ApplicationRecord
  belongs_to :card
  belongs_to :user

  validates :user_id, uniqueness: { scope: :card_id }
end
