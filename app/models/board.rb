class Board < ApplicationRecord
  enum :visibility, { private: 0, public: 1 }, prefix: true

  belongs_to :owner, class_name: "User"
  has_many :board_memberships, dependent: :destroy
  has_many :members, through: :board_memberships, source: :user
  has_many :lists, -> { order(:position) }, dependent: :destroy, inverse_of: :board
  has_many :cards, through: :lists
  has_many :labels, dependent: :destroy
  has_many :webhooks, dependent: :destroy
  has_many :activities, dependent: :destroy

  validates :name, presence: true, length: { maximum: 120 }

  after_create :add_owner_as_admin

  # Effective role of a user on this board (owner always counts as admin).
  def role_for(user)
    return nil unless user
    return :admin if owner_id == user.id

    board_memberships.find_by(user_id: user.id)&.role&.to_sym
  end

  def member?(user)
    role_for(user).present?
  end

  private

  def add_owner_as_admin
    board_memberships.find_or_create_by!(user: owner) { |m| m.role = :admin }
  end
end
