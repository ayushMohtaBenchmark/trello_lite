class Webhook < ApplicationRecord
  EVENTS = %w[
    card.created card.updated card.moved card.archived
    comment.created list.created list.updated
  ].freeze

  belongs_to :board
  has_many :webhook_deliveries, dependent: :destroy

  before_validation :ensure_secret

  validates :url, presence: true,
                  format: { with: %r{\Ahttps?://[^\s]+\z}i, message: "must be an http(s) URL" }
  validates :event_types, presence: true
  validate :event_types_supported

  scope :active, -> { where(active: true) }

  def subscribed_to?(event)
    active? && event_types.include?(event)
  end

  private

  def ensure_secret
    self.secret = SecureRandom.hex(32) if secret.blank?
  end

  def event_types_supported
    return if event_types.blank?

    unsupported = Array(event_types) - EVENTS
    return if unsupported.empty?

    errors.add(:event_types, "contains unsupported events: #{unsupported.join(', ')}")
  end
end
