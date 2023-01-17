# frozen_string_literal: true

class AdminSetsController < ApplicationController
  load_and_authorize_resource
  before_action :set_admin_set, only: [:show, :edit, :update, :destroy]

  # GET /admin_sets
  # GET /admin_sets.json
  def index
    @admin_sets = AdminSet.all
    respond_to do |format|
      format.html
      format.json { render json: AdminSetDatatable.new(params, view_context: view_context) }
    end
  end

  # GET /admin_sets/1
  # GET /admin_sets/1.json
  def show
    respond_to do |format|
      format.html
      format.json { render json: BatchProcessDetailDatatable.new(params, view_context: view_context) }
    end
  end

  # GET /admin_sets/new
  def new
    @admin_set = AdminSet.new
  end

  # GET /admin_sets/1/edit
  def edit; end

  # POST /admin_sets
  # POST /admin_sets.json
  def create
    @admin_set = AdminSet.new(admin_set_params)

    respond_to do |format|
      if @admin_set.save
        format.html { redirect_to @admin_set, notice: 'Admin set was successfully created.' }
        format.json { render :show, status: :created, location: @admin_set }
      else
        format.html { render :new }
        format.json { render json: @admin_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin_sets/1
  # PATCH/PUT /admin_sets/1.json
  def update
    respond_to do |format|
      if @admin_set.update(admin_set_params)
        format.html { redirect_to @admin_set, notice: 'Admin set was successfully updated.' }
        format.json { render :show, status: :ok, location: @admin_set }
      else
        format.html { render :edit }
        format.json { render json: @admin_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_sets/1
  # DELETE /admin_sets/1.json
  def destroy
    @admin_set.destroy!
    respond_to do |format|
      format.html { redirect_to admin_sets_url, notice: 'Admin set was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def update_manifests(admin_set_id)
    UpdateManifestsJob.perform_later(0, admin_set_id)
    respond_to do |format|
      format.html { redirect_to admin_sets_url(admin_set_id), notice: 'IIIF Manifests queued for update' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_admin_set
      @admin_set = AdminSet.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_set_params
      params.require(:admin_set).permit(:key, :label, :homepage, :summary)
    end
end
