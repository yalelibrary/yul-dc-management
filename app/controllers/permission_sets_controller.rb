# frozen_string_literal: true

class PermissionSetsController < ApplicationController
  load_and_authorize_resource except: [:permission_set_terms, :new_term, :post_permission_set_terms]
  before_action :set_permission_set, only: [:show, :edit, :update, :destroy, :permission_set_terms, :post_permission_set_terms, :new_term]

  # GET /permission_sets
  # GET /permission_sets.json
  def index
    authorize!(:view_list, PermissionSet)

    permission_sets = PermissionSet.all
    @visible_permission_sets = permission_sets.order('label ASC').select do |sets|
      User.with_role(:approver, sets).include?(current_user) ||
        User.with_role(:administrator, sets).include?(current_user) ||
        User.with_role(:sysadmin, sets).include?(current_user)
    end
  end

  def show; end

  def edit; end

  # PATCH/PUT /permission_sets/1
  # PATCH/PUT /permission_sets/1.json
  def update
    respond_to do |format|
      if @permission_set.update(permission_set_params)
        format.html { redirect_to @permission_set, notice: 'Permission set was successfully updated.' }
        format.json { render :show, status: :ok, location: @permission_set }
      else
        format.html { render :edit }
        format.json { render json: @permission_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /permission_sets
  # POST /permission_sets.json
  def create
    @permission_set = PermissionSet.new(permission_set_params)

    respond_to do |format|
      if @permission_set.save
        format.html { redirect_to @permission_set, notice: 'Permission set was successfully created.' }
        format.json { render :show, status: :created, location: @permission_set }
      else
        format.html { render :new }
        format.json { render json: @permission_set.errors, status: :unprocessable_entity }
      end
    end
  end

  def permission_set_terms
    authorize!(:update, @permission_set)
    respond_to do |format|
      format.html { render :terms }
    end
  end

  def new_term
    authorize!(:update, @permission_set)
  end

  def post_permission_set_terms
    authorize!(:update, @permission_set)
    @permission_set.activate_terms!(current_user, params[:title], params[:body])
    redirect_to permission_set_terms_permission_set_url(@permission_set)
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_permission_set
      @permission_set = PermissionSet.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def permission_set_params
      params.require(:permission_set).permit(:key, :label, :max_queue_length, permission_set_terms_attributes: [:id, :title, :body])
    end
end
