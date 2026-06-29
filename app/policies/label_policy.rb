class LabelPolicy < ApplicationPolicy
  # Labels are board configuration: only admins manage them, members may read.
  def create?  = admin?
  def update?  = admin?
  def destroy? = admin?
end
