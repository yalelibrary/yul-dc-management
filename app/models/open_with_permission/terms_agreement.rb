# frozen_string_literal: true

class OpenWithPermission::TermsAgreement < ApplicationRecord
  belongs_to :permission_set_term, class_name: "OpenWithPermission::PermissionSetTerm"
  belongs_to :permission_request_user, class_name: "OpenWithPermission::PermissionRequestUser"
end
