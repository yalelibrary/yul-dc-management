# frozen_string_literal: true

class PermissionRequestsController < ApplicationController
  load_and_authorize_resource class: OpenWithPermission::PermissionRequest
  before_action :set_permission_request, only: [:show, :edit, :update, :destroy]

  # Allows inline JS to function on show/edit page and allows FontAwesome icons to render on datatable
  content_security_policy do |policy|
    policy.script_src :self, :unsafe_inline
    policy.script_src_attr  :self, :unsafe_inline
    policy.script_src_elem  :self, :unsafe_inline
    policy.style_src :self, :unsafe_inline
    policy.style_src_elem :self, :unsafe_inline

    config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }

    config.content_security_policy_nonce_directives = %w[script-src]
  end

  # GET /permission_requests
  # GET /permission_requests.json
  def index
    authorize!(:view_list, OpenWithPermission::PermissionRequest)
    @permission_requests = OpenWithPermission::PermissionRequest.all
    respond_to do |format|
      format.html
      format.json { render json: PermissionRequestDatatable.new(params, view_context: view_context, current_ability: current_ability) }
    end
  end

  def show; end

  def edit; end

  # PATCH/PUT /permission_request/1
  # PATCH/PUT /permission_request/1.json
  def update
    old_visibility = @permission_request.new_visibility
    old_request_status = @permission_request.request_status
    respond_to do |format|
      if @permission_request.update(permission_request_params)
        send_mail if @permission_request.new_visibility != old_visibility
        if @permission_request.request_status != old_request_status
          @permission_request.approver = current_user.uid
          @permission_request.save!
          send_user_email(@permission_request)
        end
        format.html { redirect_to permission_request_path(@permission_request), notice: 'Changes saved successfully.' }
        format.json { render :show, status: :ok, location: @permission_request }
      else
        format.html { render :show }
        flash.now[:message] = @permission_request.errors.full_messages[0]
        format.json { render json: @permission_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /permission_request
  # POST /permission_request.json
  def create
    @permission_request = OpenWithPermission::PermissionRequest.new(permission_request_params)

    respond_to do |format|
      if @permission_request.save
        format.html { redirect_to @permission_request, notice: 'Permission request was successfully created.' }
        format.json { render :show, status: :created, location: @permission_request }
      else
        format.html { render :new }
        format.json { render json: @permission_request.errors, status: :unprocessable_entity }
      end
    end
  end

  def send_mail
    access_change_request = {
      approver_name: current_user.first_name + ' ' + current_user.last_name,
      permission_set_label: @permission_request.permission_set.label,
      admin_set_label: @permission_request.parent_object.admin_set.label,
      parent_object_oid: @permission_request.parent_object.oid,
      new_visibility: @permission_request.new_visibility
    }
    AccessChangeRequestMailer.with(access_change_request: access_change_request).access_change_request_email.deliver_now
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def send_user_email(permission_request)
    user_approved_notification = {
      request_user_name: @permission_request.permission_request_user.name,
      permission_set_label: @permission_request.permission_set.label,
      request_user_email: @permission_request.permission_request_user.email,
      expiration_date: @permission_request.access_until,
      parent_object_oid: @permission_request.parent_object.oid,
      parent_object_title: @permission_request.parent_object&.authoritative_json&.[]('title')&.first
    }
    user_denied_notification = {
      request_user_name: @permission_request.permission_request_user.name,
      permission_set_label: @permission_request.permission_set.label,
      request_user_email: @permission_request.permission_request_user.email,
      parent_object_title: @permission_request.parent_object&.authoritative_json&.[]('title')&.first
    }
    if permission_request.request_status == "Approved"
      UserNotificationApprovedMailer.with(user_notification: user_approved_notification).user_notification_approved_email.deliver_now
    elsif permission_request.request_status == "Denied"
      UserNotificationDeniedMailer.with(user_notification: user_denied_notification).user_notification_denied_email.deliver_now
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_permission_request
    @permission_request = OpenWithPermission::PermissionRequest.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def permission_request_params
    params.require(:open_with_permission_permission_request).permit(:permission_set, :permission_request_user, :parent_object, :user,
    :request_status, :approver_note, :new_visibility, :change_access_type, :access_until, :approver)
  end
end
