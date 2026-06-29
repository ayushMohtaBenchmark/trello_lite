module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: %i[register login refresh logout]

      # POST /api/v1/auth/register
      def register
        user = User.new(register_params)
        user.save!
        render_auth(user, status: :created)
      end

      # POST /api/v1/auth/login
      def login
        user = User.find_by(email: params.dig(:user, :email).to_s.strip.downcase)
        if user&.authenticate(params.dig(:user, :password))
          render_auth(user)
        else
          render_error(code: "invalid_credentials",
                       message: "Email or password is incorrect", status: :unauthorized)
        end
      end

      # POST /api/v1/auth/refresh  — rotates the refresh token.
      def refresh
        tokens = Auth::TokenIssuer.rotate(params[:refresh_token])
        return render_invalid_refresh unless tokens

        render json: token_payload(tokens)
      end

      # DELETE /api/v1/auth/logout — revokes the presented refresh token.
      def logout
        Auth::TokenIssuer.revoke(params[:refresh_token])
        head :no_content
      end

      # GET /api/v1/auth/me
      def me
        render_resource(UserSerializer, current_user)
      end

      private

      def register_params
        params.require(:user).permit(:name, :email, :password)
      end

      def render_auth(user, status: :ok)
        tokens = Auth::TokenIssuer.issue_for(user)
        render json: {
          user: UserSerializer.new(user).serializable_hash,
          **token_payload(tokens)
        }, status: status
      end

      def token_payload(tokens)
        {
          access_token: tokens.access_token,
          refresh_token: tokens.refresh_token,
          token_type: "Bearer",
          expires_in: tokens.expires_in
        }
      end

      def render_invalid_refresh
        render_error(code: "invalid_refresh_token",
                     message: "Refresh token is invalid, expired, or revoked",
                     status: :unauthorized)
      end
    end
  end
end
