# frozen_string_literal: true

class ParentObjectsController < ApplicationController
  before_action :set_parent_object, only: [:show, :edit, :update, :destroy, :update_metadata]

  # GET /parent_objects
  # GET /parent_objects.json
  def index
    @parent_objects = ParentObject.page params[:page]
  end

  # GET /parent_objects/1
  # GET /parent_objects/1.json
  def show; end

  # GET /parent_objects/new
  def new
    @parent_object = ParentObject.new
  end

  # GET /parent_objects/1/edit
  def edit; end

  # POST /parent_objects
  # POST /parent_objects.json
  def create
    @parent_object = ParentObject.new(parent_object_params)
    respond_to do |format|
      if @parent_object.save
        format.html { redirect_to @parent_object, notice: 'Parent object was successfully created.' }
        format.json { render :show, status: :created, location: @parent_object }

      else
        format.html { render :new }
        format.json { render json: @parent_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /parent_objects/1
  # PATCH/PUT /parent_objects/1.json
  def update
    respond_to do |format|
      if @parent_object.update(parent_object_params)
        format.html { redirect_to @parent_object, notice: 'Parent object was successfully updated.' }
        format.json { render :show, status: :ok, location: @parent_object }
      else
        format.html { render :edit }
        format.json { render json: @parent_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /parent_objects/1
  # DELETE /parent_objects/1.json
  def destroy
    @parent_object.destroy
    respond_to do |format|
      format.html { redirect_to parent_objects_url, notice: 'Parent object was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def reindex
    ParentObject.solr_delete_all
    ParentObject.solr_index
    respond_to do |format|
      format.html { redirect_to parent_objects_url, notice: 'Parent objects have been reindexed.' }
      format.json { head :no_content }
    end
  end

  def all_metadata
    ParentObject.find_each do |po|
      po.metadata_update = true
      po.setup_metadata_job
    end
    respond_to do |format|
      format.html { redirect_to parent_objects_url, notice: 'Parent objects have been queued for metadata update.' }
      format.json { head :no_content }
    end
  end

  def update_metadata
    @parent_object.metadata_update = true
    @parent_object.setup_metadata_job
    respond_to do |format|
      format.html { redirect_to parent_objects_url, notice: 'Parent object metadata update was queued.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_parent_object
      @parent_object = ParentObject.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def parent_object_params
      params.require(:parent_object).permit(:oid, :bib, :holding, :item, :barcode, :aspace_uri, :last_ladybird_update, :last_voyager_update,
                                            :last_aspace_update, :visibility, :last_id_update, :authoritative_metadata_source_id)
    end
end
