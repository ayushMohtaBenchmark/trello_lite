require "rails_helper"

RSpec.describe Webhooks::Sender do
  let(:webhook)  { create(:webhook, url: "https://hooks.example.com/x", event_types: %w[card.created]) }
  let(:delivery) { webhook.webhook_deliveries.create!(event: "card.created", payload: { id: 9 }) }

  it "POSTs an HMAC-signed payload and marks the delivery delivered" do
    stub = stub_request(:post, "https://hooks.example.com/x")
           .with do |req|
             sig = req.headers["X-Trellolite-Signature"]
             expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", webhook.secret, req.body)
             sig == expected && req.headers["X-Trellolite-Event"] == "card.created"
           end
           .to_return(status: 200, body: "ok")

    described_class.new(delivery).call

    expect(stub).to have_been_requested
    expect(delivery.reload).to be_delivered
    expect(delivery.response_code).to eq(200)
  end

  it "marks failed and raises on non-2xx so the job retries" do
    stub_request(:post, "https://hooks.example.com/x").to_return(status: 500)
    expect { described_class.new(delivery).call }.to raise_error(Webhooks::Sender::DeliveryError)
    expect(delivery.reload).to be_failed
  end
end
