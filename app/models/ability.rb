# frozen_string_literal: true

class Ability
  include CanCan::Ability

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
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
    can :reindex_admin_set, AdminSet, roles: { name: editor_roles, users: { id: user.id } }
    can [:crud], ChildObject, parent_object: { admin_set: { roles: { name: editor_roles, users: { id: user.id } } } }
    can [:crud], ParentObject, admin_set: { roles: { name: editor_roles, users: { id: user.id } } }
    can [:view_list], [PermissionSet, PermissionRequest] if user.has_role?(:sysadmin) || user.has_role?(:approver, :any) || user.has_role?(:administrator, :any)
    can [:create_set, :crud], PermissionSet if user.has_role?(:sysadmin) || user.has_role?(:administrator, :any)
    can [:read, :approve], [PermissionSet, PermissionRequest], roles: { name: approver_roles, users: { id: user.id } }
    can [:crud, :approve], PermissionSet, roles: { name: administrator_roles, users: { id: user.id } }
    can [:create, :read], ProblemReport if user.has_role?(:sysadmin)
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def apply_sysadmin_abilities
    can :manage, User
    can :crud, AdminSet
    can :crud, PermissionSet
    can :crud, PermissionRequest
    can :read, ParentObject
    can :read, ChildObject
    can :read, PreservicaIngest
    can :read, ReoccurringJobDatatable
    can :reindex_all, ParentObject
    can :update_metadata, ParentObject
    can :sync_from_preservica, ParentObject
    can :trigger_mets_scan, ParentObject
  end

  def viewer_roles
    %w[viewer editor]
  end

  def editor_roles
    ['editor']
  end

  def approver_roles
    ['approver']
  end

  def administrator_roles
    ['administrator']
  end
end
