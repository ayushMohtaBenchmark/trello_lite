class User < ApplicationRecord
  has_secure_password

  enum :role, { member: 0, admin: 1 }

  has_many :owned_boards, class_name: "Board", foreign_key: :owner_id,
                          dependent: :destroy, inverse_of: :owner
  has_many :board_memberships, dependent: :destroy
  has_many :boards, through: :board_memberships
  has_many :refresh_tokens, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :card_assignments, dependent: :destroy
  has_many :assigned_cards, through: :card_assignments, source: :card

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  # Boards visible to this user: owned, a member of, or world-readable.
  def accessible_boards
    Board.left_joins(:board_memberships)
         .where("boards.owner_id = :id OR board_memberships.user_id = :id OR boards.visibility = :public",
                id: id, public: Board.visibilities[:public])
         .distinct
  end
end
