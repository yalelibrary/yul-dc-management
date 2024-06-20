# frozen_string_literal: true
class OpenWithPermission::PermissionRequest < ApplicationRecord
  resourcify
  belongs_to :permission_set, class_name: "OpenWithPermission::PermissionSet"
  belongs_to :permission_request_user, class_name: "OpenWithPermission::PermissionRequestUser"
  belongs_to :parent_object
  has_one :user
  before_validation :sanitize_user_input, on: [:create]
  validates :access_until, presence: { if: -> { request_status == "Approved" }, message: " can't be blank. Please select an Access Until date. This is the date the user's access will expire." }

  before_save do
    self.approved_or_denied_at = Time.zone.now if request_status_changed?
  end

  private

  def sanitize_user_input
    self.user_note = ActionView::Base.full_sanitizer.sanitize(user_note, tags: [])
    self.permission_request_user_name = ActionView::Base.full_sanitizer.sanitize(permission_request_user_name, tags: [])
  end
end
