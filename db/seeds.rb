# Idempotent demo data for Trello-Lite. Safe to run multiple times.
#
#   bin/rails db:seed
#
# Creates a demo owner + collaborator, one board with three lists, a handful of
# cards, labels and a comment so the API has something to return out of the box.

owner = User.find_or_create_by!(email: "demo@trello-lite.test") do |u|
  u.name = "Demo Owner"
  u.password = "password123"
end

collaborator = User.find_or_create_by!(email: "collaborator@trello-lite.test") do |u|
  u.name = "Casey Collaborator"
  u.password = "password123"
end

board = owner.owned_boards.find_or_create_by!(name: "Product Roadmap") do |b|
  b.description = "Demo board seeded for the Trello-Lite API"
  b.visibility = :private
end

board.board_memberships.find_or_create_by!(user: collaborator) { |m| m.role = :member }

bug     = board.labels.find_or_create_by!(name: "bug")     { |l| l.color = "#e53935" }
feature = board.labels.find_or_create_by!(name: "feature") { |l| l.color = "#43a047" }

["Backlog", "In Progress", "Done"].each_with_index do |name, i|
  list = board.lists.find_or_create_by!(name: name) { |l| l.position = i + 1 }

  next if list.cards.exists?

  3.times do |n|
    card = list.cards.create!(
      title: "#{name} card #{n + 1}",
      description: "Seeded example card.",
      creator: owner,
      position: n + 1
    )
    card.labels << [bug, feature].sample
    card.assignees << collaborator if n.even?
  end
end

first_card = board.cards.first
first_card&.comments&.find_or_create_by!(
  user: collaborator,
  body: "Looks good — let's ship it!"
)

puts "Seeded board ##{board.id} (#{board.name}) with #{board.lists.count} lists / #{board.cards.count} cards."
puts "Login as demo@trello-lite.test / password123"
