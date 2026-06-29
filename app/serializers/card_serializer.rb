class CardSerializer
  include Alba::Resource

  attributes :id, :list_id, :title, :description, :position,
             :due_on, :archived, :creator_id, :created_at, :updated_at

  attribute :board_id do |card|
    card.list.board_id
  end

  association :labels, resource: LabelSerializer
  association :assignees, resource: UserSerializer

  # Active Storage exposes a `Many` proxy rather than a plain collection, so map
  # each attachment through its serializer explicitly.
  attribute :attachments do |card|
    card.attachments.map { |att| AttachmentSerializer.new(att).serializable_hash }
  end
end
