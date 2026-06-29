class ActivitySerializer
  include Alba::Resource

  attributes :id, :board_id, :user_id, :action, :subject_type, :subject_id,
             :metadata, :created_at
end
