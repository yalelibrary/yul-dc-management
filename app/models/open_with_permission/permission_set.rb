# frozen_string_literal: true
class PermissionSet < ApplicationRecord
  has_many :permission_requests
  has_many :parent_objects
  has_many :permission_set_terms
  resourcify
  validates :key, presence: true
  validates :label, presence: true

  def add_approver(user)
    remove_administrator(user) if user.administrator(self)
    user.add_role(:approver, self)
  end

  def remove_approver(user)
    user.remove_role(:approver, self)
  end

  def add_administrator(user)
    remove_approver(user) if user.approver(self)
    user.add_role(:administrator, self)
  end

  def remove_administrator(user)
    user.remove_role(:administrator, self)
  end

  def active_permission_set_terms
    permission_set_terms.find_by('not(permission_set_terms.activated_at is null) and (permission_set_terms.inactivated_at is null)')
  end

  def inactivate_terms_by!(user)
    active_permission_set_terms&.inactivate_by!(user)
    save!
  end

  def activate_terms!(user, title, body)
    new_terms = PermissionSetTerm.create!(permission_set: self, title: title, body: body)
    new_terms.activate_by!(user)
    new_terms
  end
end
