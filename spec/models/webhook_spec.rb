require "rails_helper"

RSpec.describe Webhook, type: :model do
  it { is_expected.to belong_to(:board) }
  it { is_expected.to validate_presence_of(:url) }

  it "auto-generates a secret" do
    expect(create(:webhook).secret).to be_present
  end

  it "rejects unsupported event types" do
    webhook = build(:webhook, event_types: %w[card.created bogus.event])
    expect(webhook).not_to be_valid
    expect(webhook.errors[:event_types].join).to include("bogus.event")
  end

  it "rejects non-http URLs" do
    expect(build(:webhook, url: "ftp://example.com")).not_to be_valid
  end

  describe "#subscribed_to?" do
    it "is true only for active webhooks subscribed to the event" do
      webhook = create(:webhook, event_types: %w[card.created])
      expect(webhook.subscribed_to?("card.created")).to be(true)
      expect(webhook.subscribed_to?("card.moved")).to be(false)
      webhook.update!(active: false)
      expect(webhook.subscribed_to?("card.created")).to be(false)
    end
  end
end
