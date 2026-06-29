require "rails_helper"

RSpec.describe Auth::TokenIssuer do
  let(:user) { create(:user) }

  it "issues an access token and a persisted refresh token digest" do
    tokens = described_class.issue_for(user)
    expect(JsonWebToken.decode(tokens.access_token)[:sub]).to eq(user.id)
    expect(user.refresh_tokens.active.count).to eq(1)
    expect(user.refresh_tokens.first.token_digest).not_to eq(tokens.refresh_token)
  end

  describe ".rotate" do
    it "revokes the old token and issues a new pair" do
      first = described_class.issue_for(user)
      rotated = described_class.rotate(first.refresh_token)

      expect(rotated).to be_present
      expect(described_class.rotate(first.refresh_token)).to be_nil # one-time use
      expect(user.refresh_tokens.active.count).to eq(1)
    end

    it "returns nil for an unknown token" do
      expect(described_class.rotate("nope")).to be_nil
    end
  end

  describe ".revoke" do
    it "revokes an active refresh token" do
      tokens = described_class.issue_for(user)
      described_class.revoke(tokens.refresh_token)
      expect(user.refresh_tokens.active.count).to eq(0)
    end
  end
end
