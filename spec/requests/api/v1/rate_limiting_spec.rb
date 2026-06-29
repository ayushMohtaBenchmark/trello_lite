require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  around do |example|
    original_enabled = Rack::Attack.enabled
    original_store = Rack::Attack.cache.store
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.enabled = original_enabled
    Rack::Attack.cache.store = original_store
  end

  it "throttles repeated auth attempts with a JSON 429" do
    11.times do
      post "/api/v1/auth/login",
           params: { user: { email: "x@example.com", password: "nope" } }.to_json,
           headers: json_headers
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(json.dig("error", "code")).to eq("rate_limited")
    expect(response.headers["Retry-After"]).to be_present
  end
end
