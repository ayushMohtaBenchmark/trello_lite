class CommentPolicy < ApplicationPolicy
  # Authors may edit/delete their own comments; board admins may remove any.
  def update?  = own? || admin?
  def destroy? = own? || admin?

  private

  def own? = record.user_id == user.id
end
