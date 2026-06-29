module Api
  module V1
    class AttachmentsController < BaseController
      before_action :set_card, only: %i[index create]

      def index
        authorize @card, :show?
        render json: AttachmentSerializer.new(@card.attachments.includes(:blob)).serializable_hash
      end

      # POST /api/v1/cards/:card_id/attachments  (multipart, field: file)
      def create
        authorize @card, :update?
        @card.attachments.attach(params.require(:file))
        attachment = @card.attachments.includes(:blob).order(:created_at).last
        render_resource(AttachmentSerializer, attachment, status: :created)
      end

      def destroy
        attachment = ActiveStorage::Attachment.find(params[:id])
        authorize attachment.record, :update?
        attachment.purge_later
        head :no_content
      end

      private

      def set_card = @card = Card.find(params[:card_id])
    end
  end
end
