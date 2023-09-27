# frozen_string_literal: true

class Api::PermissionSetsController < ApplicationController
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

  def agreement_term
    begin
      term = OpenWithPermission::PermissionSetTerm.find(params[:permission_set_terms_id])
    rescue ActiveRecord::RecordNotFound
      render(json: { "title": "Term not found." }, status: 400) && (return false)
    end
    request_user = OpenWithPermission::PermissionRequestUser.where(sub: params[:sub]).first
    if request_user.nil?
      render(json: { "title": "User not found." }, status: 400) && (return false)
    else
      begin
        term_agreement = OpenWithPermission::TermsAgreement.new(permission_set_term: term, permission_request_user: request_user, agreement_ts: Time.zone.now)
        term_agreement.save!
        render json: { "title": "Success." }, status: 201
      rescue StandardError => e
        render json: { "title": e.to_s }, status: 500
      end
    end
  end
end
