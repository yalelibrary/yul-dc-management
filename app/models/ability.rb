# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user
    if user.has_role? :sysadmin
      can :manage, User
      can [:update, :create, :destroy, :read], AdminSet
      can :read, ParentObject
      can :read, ChildObject
      can :reindex_all, ParentObject
      can :update_metadata, ParentObject
      can :trigger_mets_scan, ParentObject
    else
      can :read, ParentObject, admin_set: { roles: { name: viewer_roles, users: { id: user.id } } }
      can :read, ChildObject, parent_object: { admin_set: { roles: { name: viewer_roles, users: { id: user.id } } } }
    end
    can :add, AdminSet, roles: { name: editor_roles, users: { id: user.id } }
    can [:update, :create, :destroy], ChildObject, parent_object: { admin_set: { roles: { name: editor_roles, users: { id: user.id } } } }
    can [:update_parent_in, :create_parent_in, :update_child_in, :create_child_in], AdminSet, roles: { name: editor_roles, users: { id: user.id } }
    can [:update, :create, :destroy], ParentObject, admin_set: { roles: { name: editor_roles, users: { id: user.id } } }
  end

  def viewer_roles
    %w[viewer editor]
  end

  def editor_roles
    ['editor']
  end
end
