# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user
    can :manage, User if user.has_role? :sysadmin
  end
end
