# frozen_string_literal: true

class Api::PermissionRequestsController < ApplicationController
  def create
    request = params
    parent_object = ParentObject.find(request['oid'].to_i)
    pr_user = find_or_create_user(request)
    permission_set = PermissionSet.find(parent_object.permission_set_id)
    approver = User.with_role(:approver, permission_set).first

    current_requests_count = PermissionRequest.where(permission_request_user: pr_user, request_status: nil).count
    if current_requests_count >= permission_set.max_queue_length
      render json: { "title": "Too many pending requests" }, status: 403
    else
      new_request = PermissionRequest.new(permission_set: permission_set, permission_request_user: pr_user, parent_object: parent_object, user: approver, user_note: request['note'])
      new_request.save!
      render json: { "title": "New request created" }, status: 201
    end
  end

  def find_or_create_user(request)
    pr_user = PermissionRequestUser.find_or_initialize_by(sub: request['user']['sub'])
    pr_user.name = request['user']['name']
    pr_user.email = request['user']['email']
    pr_user.email_verified = request['user']['email_verified']
    pr_user.oidc_updated_at = request['user']['oidc_updated_at']
    pr_user.save!
    pr_user
  end
end
