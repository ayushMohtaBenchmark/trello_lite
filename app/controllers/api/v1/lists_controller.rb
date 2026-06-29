module Api
  module V1
    class ListsController < BaseController
      before_action :set_board, only: %i[index create]
      before_action :set_list, only: %i[show update destroy]

      def index
        authorize @board, :show?
        render json: ListSerializer.new(paginate(@board.lists.ordered)).serializable_hash
      end

      def show
        authorize @list, :show?
        render_resource(ListSerializer, @list)
      end

      def create
        list = @board.lists.new(list_params)
        authorize list
        list.save!
        ActivityLogger.log(board: @board, user: current_user, action: "list.created", subject: list)
        Webhooks::Dispatcher.dispatch(board: @board, event: "list.created",
                                      payload: ListSerializer.new(list).serializable_hash)
        render_resource(ListSerializer, list, status: :created)
      end

      def update
        authorize @list
        @list.update!(list_params)
        Webhooks::Dispatcher.dispatch(board: @list.board, event: "list.updated",
                                      payload: ListSerializer.new(@list).serializable_hash)
        render_resource(ListSerializer, @list)
      end

      def destroy
        authorize @list
        @list.destroy!
        head :no_content
      end

      private

      def set_board = @board = Board.find(params[:board_id])
      def set_list  = @list = List.find(params[:id])
      def list_params = params.require(:list).permit(:name, :position)
    end
  end
end
