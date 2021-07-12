# frozen_string_literal: true

class ParentObjectsController < ApplicationController
  before_action :set_parent_object, only: [:show, :edit, :update, :destroy, :update_metadata, :select_thumbnail, :solr_document]
  before_action :set_paper_trail_whodunnit
  load_and_authorize_resource except: [:solr_document, :new, :create, :update_metadata, :all_metadata, :reindex, :select_thumbnail]

  # GET /parent_objects
  # GET /parent_objects.json
  def index
    respond_to do |format|
      format.html
      format.json { render json: ParentObjectDatatable.new(params, view_context: view_context, current_ability: current_ability) }
    end
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
    return unless valid_request?
    @parent_object = ParentObject.new(parent_object_params)
    authorize!(:create, @parent_object)
    batch_process_of_one
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

  def valid_request?
    return true if !ParentObject.exists?(oid: parent_object_params[:oid]) && parent_object_params[:admin_set]
    alert = parent_object_params[:admin_set] ? "The oid already exists: [#{parent_object_params[:oid]}]" : "Admin set is required to create parent object"
    respond_to do |format|
      format.html { redirect_to new_parent_object_path, flash: { alert: alert } }
      format.json { render json: { error: alert }, status: :unprocessable_entit }
    end
    false
  end

  # PATCH/PUT /parent_objects/1
  # PATCH/PUT /parent_objects/1.json
  def update
    respond_to do |format|
      invalidate_admin_set_edit unless valid_admin_set_edit?
      updated = valid_admin_set_edit? ? @parent_object.update(parent_object_params) : false

      if updated
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
    authorize!(:reindex_all, ParentObject)
    if ParentObject.cannot_reindex
      redirect_back(fallback_location: root_path, notice: 'There is already a Reindex job in progress, please wait for that job to complete before submitting a new reindex request')
    else
      ParentObject.solr_index
      respond_to do |format|
        format.html { redirect_to parent_objects_url, notice: 'Parent objects have been reindexed.' }
        format.json { head :no_content }
      end
    end
  end

  def all_metadata
    authorize!(:update_metadata, ParentObject)
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
    authorize!(:update, @parent_object)
    @parent_object.metadata_update = true
    @parent_object.setup_metadata_job
    respond_to do |format|
      format.html { redirect_back fallback_location: parent_object_url(@parent_object), notice: 'This object has been queued for a metadata update.' }
      format.json { head :no_content }
    end
  end

  def select_thumbnail
    authorize!(:update, @parent_object)
    @child_objects = ChildObject.select([:oid, :parent_object_oid, :order]).where(parent_object: @parent_object).group(:oid, :parent_object_oid, :order).order(:order).page(params[:page]).per(10)
  end

  def solr_document
    authorize!(:read, @parent_object)
    solr = SolrService.connection
    oid = params[:id].to_i
    response = solr.get 'select', params: { q: "oid_ssi:#{oid}" }
    render json: response["response"]
  end

  private

    def valid_admin_set_edit?
      !parent_object_params[:admin_set] || (parent_object_params[:admin_set] && current_user.editor(parent_object_params[:admin_set]))
    end

    def invalidate_admin_set_edit
      @parent_object.errors.add :admin_set, :invalid, message: "cannot be assigned to a set the User cannot edit"
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_parent_object
      @parent_object = ParentObject.find(params[:id])
    end

    def batch_process_of_one
      @batch_process = BatchProcess.new(user: current_user, oid: @parent_object.oid)
      @parent_object.current_batch_connection = @batch_process.batch_connections.build(connectable: @parent_object)
      @batch_process.save!
      @parent_object.current_batch_process = @batch_process
    end

    # Only allow a list of trusted parameters through.
    def parent_object_params
      cur_params = params.require(:parent_object).permit(:oid, :admin_set, :bib, :holding, :item, :barcode, :aspace_uri, :last_ladybird_update, :last_voyager_update,
                                                         :last_aspace_update, :visibility, :last_id_update, :authoritative_metadata_source_id, :viewing_direction,
                                                         :display_layout, :representative_child_oid, :rights_statement, :extent_of_digitization, :digitization_note)
      cur_params[:admin_set] = AdminSet.find_by(key: cur_params[:admin_set])
      cur_params
    end
end
