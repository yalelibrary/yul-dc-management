# frozen_string_literal: true

class PermissionRequestsController < ApplicationController
  load_and_authorize_resource class: OpenWithPermission::PermissionRequest
  before_action :set_permission_request, only: [:show, :edit, :update, :destroy]

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
    # byebug
    respond_to do |format|
      if permission_request_params.key?('new_visibility')
        send_mail
        permission_request_params = clean_params
        format.html { redirect_to permission_request_path(@permission_request), notice: 'A request to change the access type of this object was sent successfully.' }
        format.json { render :show, status: :ok, location: @permission_request }
        # byebug
        break if permission_request_params.empty?
      elsif @permission_request.update(permission_request_params)
        format.html { redirect_to permission_request_path(@permission_request), notice: 'Changes saved successfully.' }
        format.json { render :show, status: :ok, location: @permission_request }
      else
        format.html { render :edit }
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
    # byebug
    access_change_request = {
      approver_name: current_user.first_name + ' ' + current_user.last_name,
      permission_set_label: @permission_request.permission_set.label,
      admin_set_label: @permission_request.parent_object.admin_set.label,
      parent_object_oid: @permission_request.parent_object.oid,
      new_visibility: permission_request_params[:new_visibility]
    }
    AccessChangeRequestMailer.with(access_change_request: access_change_request).access_change_request_email.deliver_now
  end

  def clean_params
    # byebug
    permission_request_params.delete('new_visibility')
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_permission_request
    @permission_request = OpenWithPermission::PermissionRequest.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def permission_request_params
    params.require(:open_with_permission_permission_request).permit(:permission_set, :permission_request_user, :parent_object, :user, :request_status, :approver_note, :new_visibility)
  end
end
