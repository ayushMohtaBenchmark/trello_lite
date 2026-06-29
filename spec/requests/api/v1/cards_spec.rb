require "rails_helper"

RSpec.describe "Cards API", type: :request do
  let(:owner)  { create(:user) }
  let(:board)  { create(:board, owner: owner) }
  let(:list)   { create(:list, board: board) }
  let(:member) { create(:user).tap { |u| board.board_memberships.create!(user: u, role: :member) } }

  it "creates a card with the caller as creator" do
    post "/api/v1/lists/#{list.id}/cards", params: { card: { title: "Ship it" } }.to_json, headers: auth_headers(member)
    expect(response).to have_http_status(:created)
    expect(json["title"]).to eq("Ship it")
    expect(json["creator_id"]).to eq(member.id)
    expect(json["board_id"]).to eq(board.id)
  end

  it "syncs labels and assignees via *_ids, scoped to the board" do
    card  = create(:card, list: list, creator: owner)
    label = create(:label, board: board)
    other_label = create(:label) # different board, must be ignored

    patch "/api/v1/cards/#{card.id}",
          params: { card: { label_ids: [label.id, other_label.id], assignee_ids: [member.id] } }.to_json,
          headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    expect(json["labels"].map { |l| l["id"] }).to contain_exactly(label.id)
    expect(json["assignees"].map { |u| u["id"] }).to contain_exactly(member.id)
  end

  it "moves a card to another list at a position" do
    target = create(:list, board: board)
    a = create(:card, list: list)
    b = create(:card, list: list)

    patch "/api/v1/cards/#{b.id}/move",
          params: { list_id: target.id, position: 1 }.to_json, headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    expect(b.reload.list_id).to eq(target.id)
    expect(b.position).to eq(1)
  end

  it "emits card.archived activity when archived" do
    card = create(:card, list: list, creator: owner)
    expect {
      patch "/api/v1/cards/#{card.id}", params: { card: { archived: true } }.to_json, headers: auth_headers(owner)
    }.to change { board.activities.where(action: "card.archived").count }.by(1)
    expect(json["archived"]).to be(true)
  end

  it "lists cards without N+1 queries (Bullet guard active)" do
    3.times do
      c = create(:card, list: list)
      c.labels << create(:label, board: board)
      c.assignees << member
    end
    get "/api/v1/lists/#{list.id}/cards", headers: auth_headers(owner)
    expect(response).to have_http_status(:ok)
    expect(json.size).to eq(3)
  end

  it "deletes a card" do
    card = create(:card, list: list, creator: owner)
    delete "/api/v1/cards/#{card.id}", headers: auth_headers(owner)
    expect(response).to have_http_status(:no_content)
  end
end
