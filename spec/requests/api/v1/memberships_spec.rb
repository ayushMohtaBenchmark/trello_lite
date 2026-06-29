require "rails_helper"

RSpec.describe "Board memberships API", type: :request do
  let(:owner)   { create(:user) }
  let(:board)   { create(:board, owner: owner) }
  let!(:invitee) { create(:user, email: "invitee@example.com") }

  it "adds a member by email (admin only)" do
    post "/api/v1/boards/#{board.id}/memberships",
         params: { membership: { email: "invitee@example.com", role: "viewer" } }.to_json,
         headers: auth_headers(owner)
    expect(response).to have_http_status(:created)
    expect(json["role"]).to eq("viewer")
    expect(board.reload.role_for(invitee)).to eq(:viewer)
  end

  it "forbids non-admins from adding members" do
    member = create(:user)
    board.board_memberships.create!(user: member, role: :member)
    post "/api/v1/boards/#{board.id}/memberships",
         params: { membership: { email: invitee.email } }.to_json, headers: auth_headers(member)
    expect(response).to have_http_status(:forbidden)
  end

  it "refuses to change the owner's membership" do
    owner_membership = board.board_memberships.find_by!(user: owner)
    patch "/api/v1/boards/#{board.id}/memberships/#{owner_membership.id}",
          params: { membership: { role: "viewer" } }.to_json, headers: auth_headers(owner)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(json.dig("error", "code")).to eq("owner_immutable")
  end
end
