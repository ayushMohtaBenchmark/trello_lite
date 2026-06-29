require "rails_helper"

RSpec.describe "Lists API", type: :request do
  let(:owner)  { create(:user) }
  let(:board)  { create(:board, owner: owner) }
  let(:member) { create(:user).tap { |u| board.board_memberships.create!(user: u, role: :member) } }
  let(:viewer) { create(:user).tap { |u| board.board_memberships.create!(user: u, role: :viewer) } }

  it "lists a board's lists in order" do
    b = create(:list, board: board, position: 2)
    a = create(:list, board: board, position: 1)
    get "/api/v1/boards/#{board.id}/lists", headers: auth_headers(member)
    expect(response).to have_http_status(:ok)
    expect(json.map { |l| l["id"] }).to eq([a.id, b.id])
  end

  it "lets members create lists" do
    post "/api/v1/boards/#{board.id}/lists", params: { list: { name: "To Do" } }.to_json, headers: auth_headers(member)
    expect(response).to have_http_status(:created)
    expect(json["name"]).to eq("To Do")
  end

  it "forbids viewers from creating lists" do
    post "/api/v1/boards/#{board.id}/lists", params: { list: { name: "Nope" } }.to_json, headers: auth_headers(viewer)
    expect(response).to have_http_status(:forbidden)
  end

  it "updates and deletes a list" do
    list = create(:list, board: board)
    patch "/api/v1/lists/#{list.id}", params: { list: { name: "Doing" } }.to_json, headers: auth_headers(owner)
    expect(json["name"]).to eq("Doing")
    delete "/api/v1/lists/#{list.id}", headers: auth_headers(owner)
    expect(response).to have_http_status(:no_content)
  end
end
