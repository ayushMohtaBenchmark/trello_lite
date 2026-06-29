class CardPolicy < ApplicationPolicy
  def move? = writer?
end
