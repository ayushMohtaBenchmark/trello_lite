module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization
      include Authenticatable
      include ErrorHandling
      include Paginatable

      # Pundit authorizes against the authenticated user.
      def pundit_user = current_user

      # Render a single resource (or collection) through an Alba serializer.
      def render_resource(serializer, record, status: :ok, **params)
        render json: serializer.new(record, params: params).serializable_hash, status: status
      end
    end
  end
end
