module Cards
  # Moves a card within or across lists and renumbers the affected list(s) so
  # positions stay dense and 1-based. `position` is the desired 1-based slot.
  class Mover
    def self.call(card:, target_list: nil, position: nil)
      new(card, target_list, position).call
    end

    def initialize(card, target_list, position)
      @card = card
      @source_list = card.list
      @target_list = target_list || card.list
      @position = position
    end

    def call
      ActiveRecord::Base.transaction do
        @card.list = @target_list
        reorder(@target_list, place: @card, at: @position)
        reorder(@source_list) if @source_list.id != @target_list.id
      end
      @card.reload
    end

    private

    # Rebuilds dense positions for a list, optionally inserting `place` at slot `at`.
    def reorder(list, place: nil, at: nil)
      siblings = list.cards.where.not(id: @card.id).ordered.to_a
      if place
        index = [[at.to_i - 1, 0].max, siblings.length].min
        siblings.insert(index, place)
      end
      siblings.each_with_index do |card, i|
        card.update_columns(position: i + 1, list_id: list.id, updated_at: Time.current)
      end
    end
  end
end
