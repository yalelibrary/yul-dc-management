# frozen_string_literal: true

class OpenWithPermission::PermissionSetTerm < ApplicationRecord
  belongs_to :permission_set, class_name: "OpenWithPermission::PermissionSet"
  has_many :terms_agreements, class_name: "OpenWithPermission::TermsAgreement"
  belongs_to :inactivated_by, primary_key: 'id', class_name: 'User', optional: true
  belongs_to :activated_by, primary_key: 'id', class_name: 'User', optional: true

  attr_readonly :title, :body

  before_validation :strip_whitespace

  def strip_whitespace
    self.title = title.strip unless title.nil?
    self.body = body.strip unless body.nil?
  end

  def activate_by!(user)
    raise "Unable to activate previously activated permission set" unless activated_at.nil?
    raise "User cannot be nil" unless user
    OpenWithPermission::PermissionSetTerm.transaction do
      time = Time.zone.now
      prior_active_terms = permission_set.active_permission_set_terms
      if prior_active_terms && prior_active_terms != self
        prior_active_terms.inactivated_by = user
        prior_active_terms.inactivated_at = time
        prior_active_terms.save!
      end
      self.activated_by = user
      self.activated_at = time
      save!
    end
  end

  def inactivate_by!(user)
    raise "Unable to inactivate inactivated permission set" unless activated_at
    raise "Unable to inactivate previously inactivated permission set" unless inactivated_at.nil?
    raise "User cannot be nil" unless user
    self.inactivated_by = user
    self.inactivated_at = Time.zone.now
    save!
  end
end
