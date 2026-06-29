module Api
  module V1
    class CardsController < BaseController
      before_action :set_list, only: %i[index create]
      before_action :set_card, only: %i[show update destroy move]

      def index
        authorize @list, :show?
        cards = @list.cards.ordered.includes(:list, :labels, :assignees, attachments_attachments: :blob)
        render json: CardSerializer.new(paginate(cards)).serializable_hash
      end

      def show
        authorize @card, :show?
        render_resource(CardSerializer, loaded_card(@card))
      end

      def create
        card = @list.cards.new(card_params.merge(creator: current_user))
        authorize card
        card.save!
        apply_associations(card)
        notify_event(card, "card.created")
        render_resource(CardSerializer, loaded_card(card), status: :created)
      end

      def update
        authorize @card
        @card.assign_attributes(card_params)
        archived = @card.archived_changed? && @card.archived?
        @card.save!
        apply_associations(@card)
        notify_event(@card, archived ? "card.archived" : "card.updated")
        render_resource(CardSerializer, loaded_card(@card))
      end

      # PATCH /api/v1/cards/:id/move  { list_id?, position }
      def move
        authorize @card, :move?
        target = params[:list_id] ? List.find(params[:list_id]) : @card.list
        authorize target, :update?
        Cards::Mover.call(card: @card, target_list: target, position: params[:position])
        notify_event(@card.reload, "card.moved")
        render_resource(CardSerializer, loaded_card(@card))
      end

      def destroy
        authorize @card
        @card.destroy!
        head :no_content
      end

      private

      def set_list = @list = List.find(params[:list_id])
      def set_card = @card = Card.find(params[:id])

      def loaded_card(card)
        Card.includes(:labels, :assignees, attachments_attachments: :blob).find(card.id)
      end

      def card_params
        params.require(:card).permit(:title, :description, :position, :due_on, :archived)
      end

      # Sync label/assignee join records when *_ids arrays are supplied. Both are
      # constrained to the card's board (labels) and its members (assignees).
      def apply_associations(card)
        board = card.list.board
        if params[:card].key?(:label_ids)
          card.label_ids = board.labels.where(id: Array(params[:card][:label_ids])).pluck(:id)
        end
        if params[:card].key?(:assignee_ids)
          card.assignee_ids = board.members.where(id: Array(params[:card][:assignee_ids])).pluck(:id)
        end
      end

      def notify_event(card, event)
        board = card.list.board
        ActivityLogger.log(board: board, user: current_user, action: event, subject: card)
        Webhooks::Dispatcher.dispatch(board: board, event: event,
                                      payload: CardSerializer.new(loaded_card(card)).serializable_hash)
      end
    end
  end
end
