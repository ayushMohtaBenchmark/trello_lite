require "rails_helper"

RSpec.describe "Comments API", type: :request do
  let(:owner)  { create(:user) }
  let(:board)  { create(:board, owner: owner) }
  let(:list)   { create(:list, board: board) }
  let(:card)   { create(:card, list: list, creator: owner) }
  let(:author) { create(:user).tap { |u| board.board_memberships.create!(user: u, role: :member) } }
  let(:other)  { create(:user).tap { |u| board.board_memberships.create!(user: u, role: :member) } }

  it "creates a comment and emits an activity" do
    expect {
      post "/api/v1/cards/#{card.id}/comments", params: { comment: { body: "Nice" } }.to_json, headers: auth_headers(author)
    }.to change { board.activities.where(action: "comment.created").count }.by(1)
    expect(response).to have_http_status(:created)
    expect(json["body"]).to eq("Nice")
  end

  it "lets the author edit but forbids other members" do
    comment = create(:comment, card: card, user: author)

    patch "/api/v1/comments/#{comment.id}", params: { comment: { body: "Edited" } }.to_json, headers: auth_headers(other)
    expect(response).to have_http_status(:forbidden)

    patch "/api/v1/comments/#{comment.id}", params: { comment: { body: "Edited" } }.to_json, headers: auth_headers(author)
    expect(response).to have_http_status(:ok)
    expect(comment.reload.body).to eq("Edited")
  end

  it "allows a board admin to delete any comment" do
    comment = create(:comment, card: card, user: author)
    delete "/api/v1/comments/#{comment.id}", headers: auth_headers(owner)
    expect(response).to have_http_status(:no_content)
  end
end
