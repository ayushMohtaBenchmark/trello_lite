module Webhooks
  # Fans an event out to every active board webhook subscribed to it, creating a
  # delivery record and enqueuing a background job per subscriber.
  class Dispatcher
    def self.dispatch(board:, event:, payload:)
      board.webhooks.active.find_each do |webhook|
        next unless webhook.subscribed_to?(event)

        delivery = webhook.webhook_deliveries.create!(
          event: event, payload: payload, status: :pending
        )
        WebhookDeliveryJob.perform_later(delivery.id)
      end
    end
  end
end
