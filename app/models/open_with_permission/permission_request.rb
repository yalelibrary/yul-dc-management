# frozen_string_literal: true
class OpenWithPermission::PermissionRequest < ApplicationRecord
  resourcify
  belongs_to :permission_set, class_name: "OpenWithPermission::PermissionSet"
  belongs_to :permission_request_user, class_name: "OpenWithPermission::PermissionRequestUser"
  belongs_to :parent_object
  has_one :user
  before_validation :sanitize_user_input, on: [:create]
  validate :access_until_present?

  before_save do
    self.approved_or_denied_at = Time.zone.now if request_status_changed?
  end

  def access_until_present?
    errors.add(:base, "Allow Access Until can’t be blank. Please select an Allow Access Until date. The user’s access will expire on this date.") if request_status == "Approved" && access_until.nil?
  end

  private

  def sanitize_user_input
    self.user_note = ActionView::Base.full_sanitizer.sanitize(user_note, tags: [])
    self.permission_request_user_name = ActionView::Base.full_sanitizer.sanitize(permission_request_user_name, tags: [])
  end
end
