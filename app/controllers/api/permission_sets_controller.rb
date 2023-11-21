# frozen_string_literal: true

class Api::PermissionSetsController < ApplicationController
  # rubocop:disable Metrics/PerceivedComplexity
  def terms_api
    # check for valid parent object
    begin
      parent_object = ParentObject.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Parent Object not found" }, status: :bad_request) && (return false)
    end
    # check for permission set
    permission_set = parent_object&.permission_set
    if permission_set.nil?
      render(json: { "title": "Permission Set not found" }, status: :bad_request) && (return false)
    # check for terms on set
    elsif permission_set.permission_set_terms.blank? || !permission_set.active_permission_set_terms
      render(json: {}, status: :no_content)
    else
      term = permission_set.active_permission_set_terms
      active_term = term.slice(:id, :title, :body)
      render json: active_term.to_json
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def agreement_term
    begin
      term = OpenWithPermission::PermissionSetTerm.find(params[:permission_set_terms_id])
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Term not found." }, status: :bad_request) && (return false)
    end
    request_user = OpenWithPermission::PermissionRequestUser.where(sub: params[:sub]).first
    if request_user.nil?
      render(json: { "title": "User not found." }, status: :bad_request) && (return false)
    else
      begin
        term_agreement = OpenWithPermission::TermsAgreement.new(permission_set_term: term, permission_request_user: request_user, agreement_ts: Time.zone.now)
        term_agreement.save!
        render json: { "title": "Success." }, status: :created
      rescue StandardError => e
        render json: { "title": e.to_s }, status: :internal_server_error
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def retrieve_permissions_data
    # check for valid user
    begin
      request_user = OpenWithPermission::PermissionRequestUser.find_by!(sub: params[:sub])
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "User not found" }, status: :not_found) && (return false)
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
        "access_until": permission.access_until }
    end

    render(json: { "timestamp": timestamp, "user": { "sub": request_user.sub }, "permission_set_terms_agreed": terms_agreed, "permissions": set.reverse })
  end
  # rubocop:enable Metrics/MethodLength
end
