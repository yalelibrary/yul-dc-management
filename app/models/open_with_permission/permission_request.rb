# frozen_string_literal: true
class OpenWithPermission::PermissionRequest < ApplicationRecord
  resourcify
  belongs_to :permission_set, class_name: "OpenWithPermission::PermissionSet"
  belongs_to :permission_request_user, class_name: "OpenWithPermission::PermissionRequestUser"
  belongs_to :parent_object
  has_one :user
  before_validation :sanitize_user_input, on: [:create]

  before_save do
    self.approved_or_denied_at = Time.zone.now if request_status_changed?
  end

  private

  def sanitize_user_input
    self.user_note = ActionView::Base.full_sanitizer.sanitize(user_note, tags: [])
    self.permission_request_user_name = ActionView::Base.full_sanitizer.sanitize(permission_request_user_name, tags: [])
    permission_request_user.email = ActionView::Base.full_sanitizer.sanitize(permission_request_user.email, tags: [])
  end
end
