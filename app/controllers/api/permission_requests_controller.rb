# frozen_string_literal: true

class Api::PermissionRequestsController < ApplicationController
  def create
    request = JSON.parse(request.raw_post)
    # find parent object
    parent_object = ParentObject.find_by(oid: request['oid'])
    # find or create and update permission request user
    pr_user = PermissionRequestUser.find_or_initialize_by(sub: request['user']['sub'])
    pr_user.name = request['user']['name']
    pr_user.email = request['user']['email']
    pr_user.email_verified = request['user']['email_verified']
    pr_user.oidc_updated_at = request['user']['oidc_updated_at']
    pr_user.save!
    # find permission set
    permission_set = PermissionSet.find(parent_object.permission_set_id)
    # find approver
    approver = User.with_role(:approver, permission_set).first
    # create new request
    new_request = PermissionRequest.new(permission_set: permission_set, permission_request_user: pr_user, parent_object: parent_object, user: approver, user_note: request['note'])
    new_request.save!
  end
end
