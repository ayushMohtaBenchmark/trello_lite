class CommentSerializer
  include Alba::Resource

  attributes :id, :card_id, :body, :created_at, :updated_at
  association :user, resource: UserSerializer
end
