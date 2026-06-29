require "rails_helper"

RSpec.describe Label, type: :model do
  subject { build(:label) }

  it { is_expected.to belong_to(:board) }
  it { is_expected.to validate_presence_of(:name) }

  it "is unique per board (case-insensitive)" do
    board = create(:board)
    create(:label, board: board, name: "Bug")
    expect(build(:label, board: board, name: "bug")).not_to be_valid
  end

  it "validates hex colour format" do
    expect(build(:label, color: "red")).not_to be_valid
    expect(build(:label, color: "#abc")).to be_valid
  end
end
