class WebhookSerializer
  include Alba::Resource

  # The signing secret is returned only on create so the integrator can store it.
  attributes :id, :board_id, :url, :event_types, :active, :created_at

  attribute :secret do |webhook|
    params[:reveal_secret] ? webhook.secret : nil
  end
end
