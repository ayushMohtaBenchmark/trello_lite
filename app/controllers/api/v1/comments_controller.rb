module Api
  module V1
    class CommentsController < BaseController
      before_action :set_card, only: %i[index create]
      before_action :set_comment, only: %i[update destroy]

      def index
        authorize @card, :show?
        comments = @card.comments.recent.includes(:user)
        render json: CommentSerializer.new(paginate(comments)).serializable_hash
      end

      def create
        comment = @card.comments.new(comment_params.merge(user: current_user))
        authorize comment
        comment.save!
        board = @card.list.board
        ActivityLogger.log(board: board, user: current_user, action: "comment.created", subject: comment)
        Webhooks::Dispatcher.dispatch(board: board, event: "comment.created",
                                      payload: CommentSerializer.new(comment).serializable_hash)
        render_resource(CommentSerializer, comment, status: :created)
      end

      def update
        authorize @comment
        @comment.update!(comment_params)
        render_resource(CommentSerializer, @comment)
      end

      def destroy
        authorize @comment
        @comment.destroy!
        head :no_content
      end

      private

      def set_card    = @card = Card.find(params[:card_id])
      def set_comment = @comment = Comment.find(params[:id])
      def comment_params = params.require(:comment).permit(:body)
    end
  end
end
