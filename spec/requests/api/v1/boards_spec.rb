require "rails_helper"

RSpec.describe "Boards API", type: :request do
  let(:owner) { create(:user) }

  describe "GET /boards" do
    it "returns only accessible boards with pagination headers" do
      mine = create(:board, owner: owner)
      create(:board) # another user's private board

      get "/api/v1/boards", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(json.map { |b| b["id"] }).to contain_exactly(mine.id)
      expect(response.headers["X-Total-Count"]).to eq("1")
      expect(response.headers["X-Per-Page"]).to eq("25")
    end
  end

  describe "POST /boards" do
    it "creates a board and makes the caller an admin" do
      post "/api/v1/boards", params: { board: { name: "Roadmap" } }.to_json, headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(json["my_role"]).to eq("admin")
      expect(Board.last.owner).to eq(owner)
    end
  end

  describe "GET /boards/:id" do
    it "forbids non-members on private boards" do
      board = create(:board)
      get "/api/v1/boards/#{board.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:forbidden)
    end

    it "allows anyone to read a public board" do
      board = create(:board, :public)
      get "/api/v1/boards/#{board.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /boards/:id" do
    it "lets admins update but forbids plain members" do
      board = create(:board, owner: owner)
      member = create(:user)
      board.board_memberships.create!(user: member, role: :member)

      patch "/api/v1/boards/#{board.id}", params: { board: { name: "X" } }.to_json, headers: auth_headers(member)
      expect(response).to have_http_status(:forbidden)

      patch "/api/v1/boards/#{board.id}", params: { board: { name: "Renamed" } }.to_json, headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
      expect(board.reload.name).to eq("Renamed")
    end
  end

  describe "DELETE /boards/:id" do
    it "only allows the owner to delete" do
      board = create(:board, owner: owner)
      admin = create(:user)
      board.board_memberships.create!(user: admin, role: :admin)

      delete "/api/v1/boards/#{board.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:forbidden)

      delete "/api/v1/boards/#{board.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:no_content)
    end
  end
end
