# frozen_string_literal: true
class OpenWithPermission::PermissionRequestUser < ApplicationRecord
  has_many :permission_requests, class_name: "OpenWithPermission::PermissionRequest"
  has_many :terms_agreements, class_name: "OpenWithPermission::TermsAgreement"
  validates :sub, presence: true
  validates :name, presence: true
  validates :email, presence: true
  validates :email_verified, inclusion: { in: [true, false] }
  validates :oidc_updated_at, presence: true
  validates :netid, uniqueness: true
end
