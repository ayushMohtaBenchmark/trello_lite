class BoardMembershipPolicy < ApplicationPolicy
  def index?   = readable?
  def create?  = admin?
  def update?  = admin?
  def destroy? = admin?
end
