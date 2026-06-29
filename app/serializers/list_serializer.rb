class ListSerializer
  include Alba::Resource

  attributes :id, :board_id, :name, :position, :created_at, :updated_at

  # Cards are embedded only when explicitly requested (params[:include_cards]).
  association :cards, resource: CardSerializer, if: proc { params[:include_cards] }
end
