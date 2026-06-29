class WebhookDelivery < ApplicationRecord
  enum :status, { pending: 0, delivered: 1, failed: 2 }

  belongs_to :webhook

  scope :recent, -> { order(created_at: :desc) }
end
