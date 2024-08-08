# frozen_string_literal: true

class Api::PermissionSetsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def terms_api
    # check for valid parent object
    begin
      parent_object = ParentObject.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Parent Object not found" }, status: 400) && (return false)
    end
    # check for permission set
    permission_set = parent_object&.permission_set
    if permission_set.nil?
      render(json: { "title": "Permission Set not found" }, status: 400) && (return false)
    # check for terms on set
    elsif permission_set.permission_set_terms.blank? || !permission_set.active_permission_set_terms
      render(json: {}, status: 204)
    else
      term = permission_set.active_permission_set_terms
      active_term = term.slice(:id, :title, :body)
      render json: active_term.to_json
    end
  end

  def check_admin_status
    # check for valid parent object
    begin
      parent_object = ParentObject.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Parent Object not found" }, status: 400) && (return false)
    end
    admin_or_approver_status = "false"
    management_user = User.find_by(uid: params[:uid])
    permission_set = parent_object&.permission_set
    if permission_set.nil?
      render(json: { "is_admin_or_approver?": admin_or_approver_status }, status: 400) && (return false)
    elsif management_user.nil?
      render(json: { "is_admin_or_approver?": admin_or_approver_status }, status: 400) && (return false)
    elsif management_user.has_role?(:administrator, permission_set) || management_user.has_role?(:approver, permission_set)
      admin_or_approver_status = "true"
    else
      admin_or_approver_status = "false"
    end
    render(json: { "is_admin_or_approver?": admin_or_approver_status })
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  def agreement_term
    return unless request.headers['Authorization'] == "Bearer #{ENV['OWP_AUTH_TOKEN']}"
    begin
      term = OpenWithPermission::PermissionSetTerm.find(params[:permission_set_terms_id])
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Term not found." }, status: 400) && (return false)
    end
    begin
      request_user = find_or_create_user(params)
    rescue ActiveRecord::RecordInvalid
      render(json: { "title": "User not found." }, status: 400) && (return false)
    end
    begin
      term_agreement = OpenWithPermission::TermsAgreement.new(permission_set_term: term, permission_request_user: request_user, agreement_ts: Time.zone.now)
      term_agreement.save!
      render json: { "title": "Success." }, status: 201
    rescue StandardError => e
      render json: { "title": e.to_s }, status: 500
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def retrieve_permissions_data
    # check for valid user
    begin
      request_user = OpenWithPermission::PermissionRequestUser.find_by!(sub: params[:sub])
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "User not found" }, status: 404) && (return false)
    end

    timestamp = Time.zone.today
    term_agreements = OpenWithPermission::TermsAgreement.includes(:permission_set_term).where(permission_request_user: request_user).where.not(agreement_ts: nil)

    terms_agreed = term_agreements.map do |term_agreement|
      term_agreement.permission_set_term.id
    end
    permissions = OpenWithPermission::PermissionRequest.where(permission_request_user: request_user)

    set = permissions.map do |permission|
      { "oid": permission.parent_object_id,
        "permission_set": permission.permission_set_id,
        "permission_set_terms": OpenWithPermission::PermissionSetTerm.find_by!(permission_set: permission.permission_set).id,
        "request_status": permission.request_status,
        "request_date": permission.created_at,
        "access_until": permission.access_until,
        "user_note": permission.user_note,
        "user_full_name": request_user.name }
    end

    render(json: { "timestamp": timestamp, "user": { "sub": request_user.sub }, "permission_set_terms_agreed": terms_agreed, "permissions": set.reverse })
  end

  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
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
end
