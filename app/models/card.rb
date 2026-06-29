class Card < ApplicationRecord
  include Positionable

  belongs_to :list
  belongs_to :creator, class_name: "User"
  has_one :board, through: :list

  has_many :comments, dependent: :destroy
  has_many :card_assignments, dependent: :destroy
  has_many :assignees, through: :card_assignments, source: :user
  has_many :card_labels, dependent: :destroy
  has_many :labels, through: :card_labels

  has_many_attached :attachments

  validates :title, presence: true, length: { maximum: 255 }

  scope :active, -> { where(archived: false) }

  def positioning_scope = { list_id: list_id }
end
