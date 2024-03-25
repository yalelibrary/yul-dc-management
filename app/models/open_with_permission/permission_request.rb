# frozen_string_literal: true
class OpenWithPermission::PermissionRequest < ApplicationRecord
  resourcify
  belongs_to :permission_set, class_name: "OpenWithPermission::PermissionSet"
  belongs_to :permission_request_user, class_name: "OpenWithPermission::PermissionRequestUser"
  belongs_to :parent_object
  has_one :user

  before_save do
    self.approved_or_denied_at = Time.zone.now if request_status_changed?
  end
end
