class BoardMembership < ApplicationRecord
  enum :role, { admin: 0, member: 1, viewer: 2 }

  belongs_to :board
  belongs_to :user

  validates :user_id, uniqueness: { scope: :board_id }
end
