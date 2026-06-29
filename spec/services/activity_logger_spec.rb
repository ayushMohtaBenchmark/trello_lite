require "rails_helper"

RSpec.describe ActivityLogger do
  it "records an activity on the board feed" do
    board = create(:board)
    list  = create(:list, board: board)
    expect {
      described_class.log(board: board, user: board.owner, action: "list.created", subject: list)
    }.to change(board.activities, :count).by(1)

    activity = board.activities.last
    expect(activity.action).to eq("list.created")
    expect(activity.subject).to eq(list)
  end
end
