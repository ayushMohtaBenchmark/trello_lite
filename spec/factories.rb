FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { "password123" }
  end

  factory :board do
    association :owner, factory: :user
    sequence(:name) { |n| "Board #{n}" }
    description { "A test board" }
    visibility { :private }

    trait :public do
      visibility { :public }
    end
  end

  factory :board_membership do
    board
    user
    role { :member }
  end

  factory :label do
    board
    sequence(:name) { |n| "label-#{n}" }
    color { "#3366cc" }
  end

  factory :list do
    board
    sequence(:name) { |n| "List #{n}" }
  end

  factory :card do
    list
    association :creator, factory: :user
    sequence(:title) { |n| "Card #{n}" }
    description { "A test card" }
  end

  factory :comment do
    card
    user
    body { "A test comment" }
  end

  factory :webhook do
    board
    url { "https://hooks.example.com/endpoint" }
    event_types { %w[card.created card.moved] }
    active { true }
  end
end
