# frozen_string_literal: true

class Api::PermissionRequestsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # rubocop:disable Metrics/MethodLength
  def create
    request = params
    begin
      parent_object = ParentObject.find(request['oid'].to_i)
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Invalid Parent OID" }, status: 400) && (return false)
    end
    return unless check_parent_visibility(parent_object)
    return unless valid_json_request(request)
    pr_user = find_or_create_user(request)
    permission_set = OpenWithPermission::PermissionSet.find(parent_object.permission_set_id)
    current_requests_count = OpenWithPermission::PermissionRequest.where(permission_request_user: pr_user, request_status: nil, permission_set: permission_set).count
    if current_requests_count >= permission_set.max_queue_length
      render json: { "title": "Too many pending requests" }, status: 403
    else
      new_request = OpenWithPermission::PermissionRequest.new(
        permission_set: permission_set,
        permission_request_user: pr_user,
        parent_object: parent_object,
        user_note: request['permission_request']['user_note'].presence || request['user_note']
      )
      new_request.save!
      render json: { "title": "New request created" }, status: 201
    end
  end
  # rubocop:enable Metrics/MethodLength

  def check_parent_visibility(parent_object)
    if parent_object.visibility == "Private"
      render(json: { "title": "Parent Object is private" }, status: 400) && (return false)
    elsif parent_object.visibility == "Public"
      render(json: { "title": "Parent Object is public, permission not required" }, status: 400) && (return false)
    end
    true
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def valid_json_request(request)
    if request['user_email'].blank?
      render(json: { "title": "User email is missing" }, status: 400) && (return false)
    elsif request['user_full_name'].blank?
      render(json: { "title": "User name is missing" }, status: 400) && (return false)
    elsif request['user_netid'].blank?
      render(json: { "title": "User netid is missing" }, status: 400) && (return false)
    elsif request['user_note'].blank?
      render(json: { "title": "User reason for request is missing" }, status: 400) && (return false)
    elsif request['user_sub'].blank?
      render(json: { "title": "User subject is missing" }, status: 400) && (return false)
    end
    true
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def find_or_create_user(request)
    pr_user = OpenWithPermission::PermissionRequestUser.find_or_initialize_by(sub: request['user_sub'])
    pr_user.name = request['user_full_name'].presence || request['permission_request']['user_full_name']
    pr_user.email = request['user_email']
    pr_user.netid = request['user_netid']
    pr_user.email_verified = true
    pr_user.oidc_updated_at = Time.zone.now
    pr_user.save!
    pr_user
  end
end
