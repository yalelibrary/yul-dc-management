# frozen_string_literal: true

class Api::PermissionRequestsController < ApplicationController
  before_action :check_authorization
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
    return unless valid_parent(parent_object)
    return unless valid_user(request['user_netid'])
    pr_user = find_or_create_user(request)
    permission_set = OpenWithPermission::PermissionSet.find(parent_object.permission_set_id)
    return unless valid_json_request(request, pr_user, parent_object, permission_set)
    # current_requests_count = OpenWithPermission::PermissionRequest.where(permission_request_user: pr_user, request_status: "Pending", permission_set: permission_set).count
    # if current_requests_count >= permission_set.max_queue_length
    #   render json: { "title": "Too many pending requests" }, status: 403
    # else
      new_request = OpenWithPermission::PermissionRequest.new(
        permission_set: permission_set,
        permission_request_user: pr_user,
        parent_object: parent_object,
        permission_request_user_name: request['user_full_name'],
        user_note: request['user_note']
      )
      new_request.save!
      send_new_request_mail(new_request)
      render json: { "title": "New request created" }, status: 201
    # end
  end
  # rubocop:disable Metrics/MethodLength

  def valid_parent(parent_object)
    if parent_object.visibility == "Private"
      render(json: { "title": "Parent Object is private" }, status: 400) && (return false)
    elsif parent_object.visibility == "Public"
      render(json: { "title": "Parent Object is public, permission not required" }, status: 400) && (return false)
    end
    true
  end

  def valid_user(user_netid)
    if user_netid.present?
      begin
        management_user = User.find(netid: user_netid)
      rescue ActiveRecord::RecordNotFound
        return true      
      end
      if management_user.nil?
        return true
      elsif management_user.has_role?(:administrator, permission_set) || management_user.has_role?(:approver, permission_set)
        render(json: { "title": "User is admin or approver" }, status: 400) && (return false)
      end
    end
    true
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def valid_json_request(request, pr_user, parent_object, permission_set)
    pending_requests_per_parent = OpenWithPermission::PermissionRequest.where(permission_request_user: pr_user, request_status: "Pending", permission_set: permission_set, parent_object: parent_object).count
    pending_requests_per_permission_set = OpenWithPermission::PermissionRequest.where(permission_request_user: pr_user, request_status: "Pending", permission_set: permission_set).count
    if pending_requests_per_parent >= 1
      render json: { "title": "Too many pending requests for object" }, status: 403
    elsif pending_requests_per_permission_set >= permission_set.max_queue_length
      render json: { "title": "Too many pending requests for set" }, status: 403
    elsif request['user_email'].blank?
      render(json: { "title": "User email is missing" }, status: 400) && (return false)
    elsif request['user_full_name'].blank?
      render(json: { "title": "User name is missing" }, status: 400) && (return false)
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
    pr_user.name = request['user_full_name']
    pr_user.email = request['user_email']
    pr_user.netid = request['user_netid']
    pr_user.email_verified = true
    pr_user.oidc_updated_at = Time.zone.now
    pr_user.save!
    pr_user
  end

  # rubocop:disable Metrics/AbcSize
  def send_new_request_mail(new_request)
    new_permission_request = {
      permission_request_id: new_request.id,
      permission_set_label: new_request.permission_set.label,
      parent_object_oid: new_request.parent_object.oid,
      parent_object_title: new_request.parent_object&.authoritative_json&.[]('title')&.first,
      requester_name: new_request.permission_request_user.name,
      requester_email: new_request.permission_request_user.email,
      requester_note: new_request.user_note
    }
    admins_and_approvers = []
    User.all.each do |user|
      admins_and_approvers << user if user.has_role?(:administrator, new_request.permission_set) || user.has_role?(:approver, new_request.permission_set)
    end
    admins_and_approvers.each do |user|
      new_permission_request[:approver_name] = user.first_name + ' ' + user.last_name
      NewPermissionRequestMailer.with(new_permission_request: new_permission_request).new_permission_request_email(user.email).deliver_now
    end
  end
  # rubocop:enable Metrics/AbcSize
end
