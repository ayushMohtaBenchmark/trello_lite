require "rails_helper"

RSpec.describe "Labels API", type: :request do
  let(:owner)  { create(:user) }
  let(:board)  { create(:board, owner: owner) }
  let(:member) { create(:user).tap { |u| board.board_memberships.create!(user: u, role: :member) } }

  it "lets admins create labels" do
    post "/api/v1/boards/#{board.id}/labels", params: { label: { name: "urgent", color: "#ff0000" } }.to_json, headers: auth_headers(owner)
    expect(response).to have_http_status(:created)
    expect(json["name"]).to eq("urgent")
  end

  it "forbids non-admins from creating labels but allows reading" do
    create(:label, board: board, name: "bug")
    post "/api/v1/boards/#{board.id}/labels", params: { label: { name: "x" } }.to_json, headers: auth_headers(member)
    expect(response).to have_http_status(:forbidden)

    get "/api/v1/boards/#{board.id}/labels", headers: auth_headers(member)
    expect(response).to have_http_status(:ok)
    expect(json.size).to eq(1)
  end
end
