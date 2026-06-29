require "rails_helper"

RSpec.describe "Auth API", type: :request do
  describe "POST /auth/register" do
    it "creates a user and returns a token pair" do
      post "/api/v1/auth/register",
           params: { user: { name: "Ada", email: "ada@example.com", password: "password123" } }.to_json,
           headers: json_headers
      expect(response).to have_http_status(:created)
      expect(json["access_token"]).to be_present
      expect(json["refresh_token"]).to be_present
      expect(json.dig("user", "email")).to eq("ada@example.com")
    end

    it "returns a validation error for bad input" do
      post "/api/v1/auth/register",
           params: { user: { name: "", email: "nope", password: "x" } }.to_json,
           headers: json_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json.dig("error", "code")).to eq("validation_failed")
    end
  end

  describe "POST /auth/login" do
    let!(:user) { create(:user, email: "log@example.com", password: "password123") }

    it "returns tokens for valid credentials" do
      post "/api/v1/auth/login",
           params: { user: { email: "log@example.com", password: "password123" } }.to_json,
           headers: json_headers
      expect(response).to have_http_status(:ok)
      expect(json["access_token"]).to be_present
    end

    it "401s for invalid credentials" do
      post "/api/v1/auth/login",
           params: { user: { email: "log@example.com", password: "wrong" } }.to_json,
           headers: json_headers
      expect(response).to have_http_status(:unauthorized)
      expect(json.dig("error", "code")).to eq("invalid_credentials")
    end
  end

  describe "refresh + logout lifecycle" do
    let(:user) { create(:user) }

    it "rotates the refresh token (one-time use) and revokes on logout" do
      tokens = Auth::TokenIssuer.issue_for(user)

      post "/api/v1/auth/refresh", params: { refresh_token: tokens.refresh_token }.to_json, headers: json_headers
      expect(response).to have_http_status(:ok)
      new_refresh = json["refresh_token"]

      # original token is now consumed
      post "/api/v1/auth/refresh", params: { refresh_token: tokens.refresh_token }.to_json, headers: json_headers
      expect(response).to have_http_status(:unauthorized)

      delete "/api/v1/auth/logout", params: { refresh_token: new_refresh }.to_json, headers: json_headers
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /auth/me" do
    it "requires a valid access token" do
      get "/api/v1/auth/me", headers: json_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the authenticated user" do
      user = create(:user)
      get "/api/v1/auth/me", headers: auth_headers(user)
      expect(json["email"]).to eq(user.email)
    end
  end
end
