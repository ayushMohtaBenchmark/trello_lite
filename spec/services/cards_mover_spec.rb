require "rails_helper"

RSpec.describe Cards::Mover do
  let(:board) { create(:board) }
  let(:list)  { create(:list, board: board) }

  it "reorders cards densely within a list" do
    a = create(:card, list: list)
    b = create(:card, list: list)
    c = create(:card, list: list)

    described_class.call(card: c, target_list: list, position: 1)

    expect([a, b, c].map { |card| card.reload.position }).to eq([2, 3, 1])
  end

  it "moves a card to another list and renumbers both" do
    source = list
    target = create(:list, board: board)
    a = create(:card, list: source)
    b = create(:card, list: source)
    create(:card, list: target)

    described_class.call(card: a, target_list: target, position: 1)

    expect(a.reload.list_id).to eq(target.id)
    expect(a.position).to eq(1)
    expect(b.reload.position).to eq(1)         # source renumbered
    expect(target.cards.ordered.first).to eq(a)
  end
end
