require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe Webhooks::Dispatcher do
  let(:board) { create(:board) }

  it "creates a delivery and enqueues a job per subscribed webhook" do
    create(:webhook, board: board, event_types: %w[card.created])
    create(:webhook, board: board, event_types: %w[card.moved]) # not subscribed
    create(:webhook, board: board, event_types: %w[card.created], active: false) # inactive

    expect {
      described_class.dispatch(board: board, event: "card.created", payload: { id: 1 })
    }.to have_enqueued_job(WebhookDeliveryJob).exactly(:once)

    expect(WebhookDelivery.count).to eq(1)
    expect(WebhookDelivery.first).to be_pending
  end
end
