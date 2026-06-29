class WebhookDeliverySerializer
  include Alba::Resource

  attributes :id, :webhook_id, :event, :status, :response_code,
             :attempts, :delivered_at, :created_at
end
