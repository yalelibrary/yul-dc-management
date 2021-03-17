# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :read, :update, :destroy, to: :crud
    return unless user
    if user.has_role? :sysadmin
      can :manage, User
      can :crud, AdminSet
      can :read, ParentObject
      can :read, ChildObject
      can :reindex_all, ParentObject
      can :update_metadata, ParentObject
      can :trigger_mets_scan, ParentObject
    end
    can :add, AdminSet, roles: { name: editor_roles, users: { id: user.id } }
    can [:crud], ChildObject, parent_object: { admin_set: { roles: { name: editor_roles, users: { id: user.id } } } }
    can [:crud], ParentObject, admin_set: { roles: { name: editor_roles, users: { id: user.id } } }
  end

  def viewer_roles
    %w[viewer editor]
  end

  def editor_roles
    ['editor']
  end
end
