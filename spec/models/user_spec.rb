require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to have_secure_password }
  it { is_expected.to have_many(:owned_boards) }
  it { is_expected.to have_many(:board_memberships).dependent(:destroy) }

  it "normalizes email to lowercase" do
    user = create(:user, email: "MixedCase@Example.COM")
    expect(user.email).to eq("mixedcase@example.com")
  end

  it "rejects duplicate emails case-insensitively" do
    create(:user, email: "dupe@example.com")
    dup = build(:user, email: "DUPE@example.com")
    expect(dup).not_to be_valid
  end

  it "requires a password of at least 8 characters" do
    expect(build(:user, password: "short")).not_to be_valid
  end

  describe "#accessible_boards" do
    let(:user) { create(:user) }

    it "includes owned, member, and public boards but not private ones" do
      owned   = create(:board, owner: user)
      member  = create(:board)
      member.board_memberships.create!(user: user, role: :member)
      public_board = create(:board, :public)
      private_board = create(:board)

      ids = user.accessible_boards.pluck(:id)
      expect(ids).to include(owned.id, member.id, public_board.id)
      expect(ids).not_to include(private_board.id)
    end
  end
end
