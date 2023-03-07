# frozen_string_literal: true
class PermissionRequestUser < ApplicationRecord
  has_many :permission_requests
  has_many :terms_agreements
  validates :sub, presence: true
  validates :name, presence: true
  validates :email, presence: true
  validates :email_verified, inclusion: { in: [true, false] }
  validates :oidc_updated_at, presence: true
end
