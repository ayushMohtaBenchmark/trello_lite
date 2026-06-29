module Api
  module V1
    class LabelsController < BaseController
      before_action :set_board, only: %i[index create]
      before_action :set_label, only: %i[update destroy]

      def index
        authorize @board, :show?
        render json: LabelSerializer.new(paginate(@board.labels.order(:name))).serializable_hash
      end

      def create
        label = @board.labels.new(label_params)
        authorize label
        label.save!
        render_resource(LabelSerializer, label, status: :created)
      end

      def update
        authorize @label
        @label.update!(label_params)
        render_resource(LabelSerializer, @label)
      end

      def destroy
        authorize @label
        @label.destroy!
        head :no_content
      end

      private

      def set_board = @board = Board.find(params[:board_id])
      def set_label = @label = Label.find(params[:id])
      def label_params = params.require(:label).permit(:name, :color)
    end
  end
end
