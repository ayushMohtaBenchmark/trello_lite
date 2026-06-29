# Records an entry in a board's append-only activity feed.
class ActivityLogger
  def self.log(board:, action:, user: nil, subject: nil, metadata: {})
    board.activities.create!(user: user, action: action, subject: subject, metadata: metadata)
  end
end
