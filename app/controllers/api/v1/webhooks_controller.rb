module Api
  module V1
    class WebhooksController < BaseController
      before_action :set_board, only: %i[index create]
      before_action :set_webhook, only: %i[show update destroy]

      def index
        authorize @board, :update?  # board admins only
        render json: WebhookSerializer.new(paginate(@board.webhooks.order(:id))).serializable_hash
      end

      def show
        authorize @webhook
        render_resource(WebhookSerializer, @webhook)
      end

      def create
        webhook = @board.webhooks.new(webhook_params)
        authorize webhook
        webhook.save!
        # Secret is revealed exactly once, on creation.
        render_resource(WebhookSerializer, webhook, status: :created, reveal_secret: true)
      end

      def update
        authorize @webhook
        @webhook.update!(webhook_params)
        render_resource(WebhookSerializer, @webhook)
      end

      def destroy
        authorize @webhook
        @webhook.destroy!
        head :no_content
      end

      private

      def set_board   = @board = Board.find(params[:board_id])
      def set_webhook = @webhook = Webhook.find(params[:id])
      def webhook_params = params.require(:webhook).permit(:url, :active, event_types: [])
    end
  end
end
