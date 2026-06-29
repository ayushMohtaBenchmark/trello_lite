# Base policy. Role resolution is centralised here: every record knows (directly
# or via association) which board it belongs to, and a user's board role
# (:admin, :member, :viewer, or nil) drives all permissions.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?   = false
  def show?    = readable?
  def create?  = writer?
  def update?  = writer?
  def destroy? = writer?

  protected

  def board
    case record
    when Board            then record
    when List, Label, Webhook, BoardMembership then record.board
    when Card             then record.list.board
    when Comment          then record.card.list.board
    else record.try(:board)
    end
  end

  def role
    board&.role_for(user)
  end

  def member?   = role.present?
  def admin?    = role == :admin
  def writer?   = %i[admin member].include?(role)
  def readable? = member? || board&.visibility_public?

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
