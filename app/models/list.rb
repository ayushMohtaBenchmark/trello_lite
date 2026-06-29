class List < ApplicationRecord
  include Positionable

  belongs_to :board
  has_many :cards, -> { order(:position) }, dependent: :destroy, inverse_of: :list

  validates :name, presence: true, length: { maximum: 120 }

  def positioning_scope = { board_id: board_id }
end
