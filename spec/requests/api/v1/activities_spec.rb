require "rails_helper"

RSpec.describe "Activities API", type: :request do
  let(:owner) { create(:user) }
  let(:board) { create(:board, owner: owner) }

  it "returns the board activity feed, most recent first" do
    ActivityLogger.log(board: board, user: owner, action: "list.created")
    ActivityLogger.log(board: board, user: owner, action: "card.created")

    get "/api/v1/boards/#{board.id}/activities", headers: auth_headers(owner)
    expect(response).to have_http_status(:ok)
    expect(json.first["action"]).to eq("card.created")
    expect(json.size).to eq(2)
  end
end
