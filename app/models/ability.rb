# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user
    can :manage, User if user.has_role? :sysadmin
    can :reindex_all, ParentObject if user.has_role? :sysadmin
    can :update_metadata, ParentObject if user.has_role? :sysadmin
    can :trigger_mets_scan, ParentObject if user.has_role? :sysadmin
  end
end
