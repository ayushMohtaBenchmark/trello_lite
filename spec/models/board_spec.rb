require "rails_helper"

RSpec.describe Board, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to belong_to(:owner).class_name("User") }
  it { is_expected.to have_many(:lists).dependent(:destroy) }

  it "adds the owner as an admin member on creation" do
    board = create(:board)
    expect(board.role_for(board.owner)).to eq(:admin)
    expect(board.board_memberships.find_by(user: board.owner).role).to eq("admin")
  end

  describe "#role_for" do
    let(:board) { create(:board) }

    it "returns the membership role for a member" do
      member = create(:user)
      board.board_memberships.create!(user: member, role: :viewer)
      expect(board.role_for(member)).to eq(:viewer)
    end

    it "returns nil for a non-member" do
      expect(board.role_for(create(:user))).to be_nil
    end
  end
end
