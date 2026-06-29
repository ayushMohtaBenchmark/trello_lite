module Api
  module V1
    class BoardMembershipsController < BaseController
      before_action :set_board
      before_action :set_membership, only: %i[update destroy]

      def index
        authorize @board, :show?
        members = @board.board_memberships.includes(:user).order(:id)
        render json: BoardMembershipSerializer.new(paginate(members)).serializable_hash
      end

      # Adds a member by email: { membership: { email:, role: } }
      def create
        authorize @board, :manage_members?
        user = User.find_by!(email: params.dig(:membership, :email).to_s.strip.downcase)
        membership = @board.board_memberships.find_or_initialize_by(user: user)
        membership.role = params.dig(:membership, :role) || :member
        membership.save!
        render_resource(BoardMembershipSerializer, membership, status: :created)
      end

      def update
        authorize @board, :manage_members?
        return render_owner_locked if owner_membership?
        @membership.update!(role: params.dig(:membership, :role))
        render_resource(BoardMembershipSerializer, @membership)
      end

      def destroy
        authorize @board, :manage_members?
        return render_owner_locked if owner_membership?
        @membership.destroy!
        head :no_content
      end

      private

      def set_board = @board = Board.find(params[:board_id])
      def set_membership = @membership = @board.board_memberships.find(params[:id])
      def owner_membership? = @membership.user_id == @board.owner_id

      def render_owner_locked
        render_error(code: "owner_immutable",
                     message: "The board owner's membership cannot be changed",
                     status: :unprocessable_entity)
      end
    end
  end
end
