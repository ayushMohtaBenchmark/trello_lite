class BoardSerializer
  include Alba::Resource

  attributes :id, :name, :description, :visibility, :owner_id, :created_at, :updated_at

  association :owner, resource: UserSerializer

  # The requesting user's effective role, when a current_user param is supplied.
  attribute :my_role do |board|
    params[:current_user] && board.role_for(params[:current_user])
  end
end
