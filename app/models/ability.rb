# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :read, :update, :destroy, to: :crud
    return unless user
    can :create_new, ParentObject if user.roles.find_by(name: :editor)
    if user.has_role? :sysadmin
      apply_sysadmin_abilities
    else
      can :read, ParentObject, admin_set: { roles: { name: viewer_roles, users: { id: user.id } } }
      can :read, ChildObject, parent_object: { admin_set: { roles: { name: viewer_roles, users: { id: user.id } } } }
    end
    can :add_member, AdminSet, roles: { name: editor_roles, users: { id: user.id } }
    can :export, AdminSet, roles: { name: editor_roles, users: { id: user.id } }
    can :reindex_admin_set, AdminSet, roles: { name: editor_roles, users: { id: user.id } }
    can [:crud], ChildObject, parent_object: { admin_set: { roles: { name: editor_roles, users: { id: user.id } } } }
    can [:crud], ParentObject, admin_set: { roles: { name: editor_roles, users: { id: user.id } } }
  end

  def apply_sysadmin_abilities
    can :manage, User
    can :crud, AdminSet
    can :read, ParentObject
    can :read, ChildObject
    can :read, PreservicaIngest
    can :read, ReoccurringJobDatatable
    can :reindex_all, ParentObject
    can :update_metadata, ParentObject
    can :trigger_mets_scan, ParentObject
  end

  def viewer_roles
    %w[viewer editor]
  end

  def editor_roles
    ['editor']
  end
end
