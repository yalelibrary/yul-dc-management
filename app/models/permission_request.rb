# frozen_string_literal: true
class PermissionRequest < ApplicationRecord
  resourcify
  belongs_to :permission_set
  belongs_to :permission_request_user
  belongs_to :parent_object
  belongs_to :user
end
