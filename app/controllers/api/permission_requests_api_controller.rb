# frozen_string_literal: true

class PermissionRequestsApiController < ApplicationController
  skip_before_action :authenticate_user!


  def create
    permission_request = JSON.parse(request.raw_post)
    parent_object = ParentObject.find_by(oid: permission_request['oid'])
    note = permission_request['user_note']
    user = permission_request['user']
    permission_set = parent_object.permission_set
    permission_request_user = PermissionRequestUser.find_or_initialize_by(sub: user['sub'])
    permission_request_user.name = user['name']
    permission_request_user.email = user['email']
    permission_request_user.email_verified = user['email_verified']
    permission_request_user.oidc_updated_at = user['oidc_updated_at']
    permission_request_user.save!
  end

end
