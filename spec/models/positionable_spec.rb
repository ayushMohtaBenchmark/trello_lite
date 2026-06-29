require "rails_helper"

RSpec.describe Positionable, type: :model do
  it "appends new lists to the end of their board" do
    board = create(:board)
    a = create(:list, board: board)
    b = create(:list, board: board)
    expect([a.position, b.position]).to eq([1, 2])
  end

  it "scopes card positions per list" do
    list1 = create(:list)
    list2 = create(:list)
    c1 = create(:card, list: list1)
    c2 = create(:card, list: list2)
    expect(c1.position).to eq(1)
    expect(c2.position).to eq(1)
  end

  it "respects an explicit position" do
    list = create(:list)
    card = create(:card, list: list, position: 5)
    expect(card.position).to eq(5)
  end
end
