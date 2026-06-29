module Api
  module V1
    class ActivitiesController < BaseController
      before_action :set_board

      def index
        authorize @board, :show?
        activities = @board.activities.recent
        render json: ActivitySerializer.new(paginate(activities)).serializable_hash
      end

      private

      def set_board = @board = Board.find(params[:board_id])
    end
  end
end
