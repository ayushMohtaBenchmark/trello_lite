class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  # Retry transient failures (timeouts, non-2xx) with exponential backoff.
  retry_on Webhooks::Sender::DeliveryError, attempts: 5, wait: :polynomially_longer
  retry_on Timeout::Error, attempts: 5, wait: :polynomially_longer

  # If the delivery/webhook was deleted, there is nothing to do.
  discard_on ActiveRecord::RecordNotFound

  def perform(delivery_id)
    delivery = WebhookDelivery.find(delivery_id)
    Webhooks::Sender.new(delivery).call
  end
end
