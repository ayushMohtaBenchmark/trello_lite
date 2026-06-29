require "rails_helper"

RSpec.describe JsonWebToken do
  it "round-trips a payload" do
    token = described_class.encode({ sub: 42 })
    expect(described_class.decode(token)[:sub]).to eq(42)
  end

  it "returns nil for a tampered token" do
    expect(described_class.decode("not.a.jwt")).to be_nil
  end

  it "returns nil for an expired token" do
    token = described_class.encode({ sub: 1 }, exp: 1.hour.ago)
    expect(described_class.decode(token)).to be_nil
  end
end
