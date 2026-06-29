require "rails_helper"

RSpec.describe "Webhooks API", type: :request do
  let(:owner)  { create(:user) }
  let(:board)  { create(:board, owner: owner) }
  let(:member) { create(:user).tap { |u| board.board_memberships.create!(user: u, role: :member) } }

  it "creates a webhook and reveals the secret exactly once" do
    post "/api/v1/boards/#{board.id}/webhooks",
         params: { webhook: { url: "https://hooks.example.com/x", event_types: ["card.created"] } }.to_json,
         headers: auth_headers(owner)
    expect(response).to have_http_status(:created)
    expect(json["secret"]).to be_present

    webhook_id = json["id"]
    get "/api/v1/webhooks/#{webhook_id}", headers: auth_headers(owner)
    expect(json["secret"]).to be_nil # not revealed on subsequent reads
  end

  it "forbids non-admins" do
    get "/api/v1/boards/#{board.id}/webhooks", headers: auth_headers(member)
    expect(response).to have_http_status(:forbidden)
  end
end
