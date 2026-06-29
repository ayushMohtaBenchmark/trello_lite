class WebhookPolicy < ApplicationPolicy
  # Webhooks expose board data externally; restrict entirely to admins.
  def index?   = admin?
  def show?    = admin?
  def create?  = admin?
  def update?  = admin?
  def destroy? = admin?
end
