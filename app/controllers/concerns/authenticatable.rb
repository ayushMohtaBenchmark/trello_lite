# Stateless JWT authentication. Expects `Authorization: Bearer <access_token>`.
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  def authenticate_user!
    return if current_user

    render_error(code: "unauthorized", message: "Invalid or missing access token",
                 status: :unauthorized)
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = resolve_user_from_token
  end

  private

  def resolve_user_from_token
    header = request.headers["Authorization"]
    return nil unless header&.start_with?("Bearer ")

    payload = JsonWebToken.decode(header.split(" ", 2).last)
    return nil unless payload && payload[:sub]

    User.find_by(id: payload[:sub])
  end
end
