class UserSerializer
  include Alba::Resource

  attributes :id, :name, :email, :role, :created_at
end
