module Api
  module V1
    class BoardsController < BaseController
      before_action :set_board, only: %i[show update destroy]

      def index
        boards = policy_scope(Board).includes(:owner).order(:name)
        render json: BoardSerializer.new(paginate(boards),
                                         params: { current_user: current_user }).serializable_hash
      end

      def show
        authorize @board
        render_resource(BoardSerializer, @board, current_user: current_user)
      end

      def create
        board = current_user.owned_boards.new(board_params)
        authorize board
        board.save!
        ActivityLogger.log(board: board, user: current_user, action: "board.created", subject: board)
        render_resource(BoardSerializer, board, status: :created, current_user: current_user)
      end

      def update
        authorize @board
        @board.update!(board_params)
        render_resource(BoardSerializer, @board, current_user: current_user)
      end

      def destroy
        authorize @board
        @board.destroy!
        head :no_content
      end

      private

      def set_board = @board = Board.find(params[:id])

      def board_params = params.require(:board).permit(:name, :description, :visibility)
    end
  end
end
