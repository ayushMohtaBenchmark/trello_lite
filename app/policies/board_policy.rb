class BoardPolicy < ApplicationPolicy
  def index?   = true
  def create?  = user.present?
  def show?    = readable?
  def update?  = admin?
  def destroy? = record.owner_id == user.id
  def manage_members? = admin?

  class Scope < Scope
    def resolve
      user.accessible_boards
    end
  end
end
