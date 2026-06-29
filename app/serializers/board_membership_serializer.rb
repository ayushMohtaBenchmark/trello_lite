class BoardMembershipSerializer
  include Alba::Resource

  attributes :id, :board_id, :role, :created_at
  association :user, resource: UserSerializer
end
