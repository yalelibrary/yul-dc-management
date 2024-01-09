# frozen_string_literal: true

class ParentObjectsController < ApplicationController
  before_action :set_parent_object, only: [:show, :edit, :update, :destroy, :update_metadata, :select_thumbnail, :solr_document]
  before_action :set_paper_trail_whodunnit
  before_action :set_permission_set, only: [:edit, :update]
  load_and_authorize_resource except: [:solr_document, :new, :create, :update_metadata, :all_metadata, :reindex, :select_thumbnail, :update_manifests, :update_digital_objects]

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
    @parent_object.oid = OidMinterService.generate_oids(1).first
    @parent_object.authoritative_metadata_source = MetadataSource.find_by(metadata_cloud_name: 'aspace')
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
        queue_parent_metadata_update
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
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def update
    respond_to do |format|
      parent_object = ParentObject.find(params[:id])
      permission_set = parent_object&.permission_set
      permission_set_param = OpenWithPermission::PermissionSet.find(parent_object_params[:permission_set_id]) if parent_object_params[:permission_set_id].present?

      authorize!(:owp_access, permission_set) if parent_object.visibility == "Open with Permission" && parent_object.visibility != parent_object_params[:visibility]

      authorize!(:owp_access, permission_set) if permission_set.present? &&  permission_set != permission_set_param

      authorize!(:owp_access, permission_set_param) if permission_set_param.present?

      invalidate_admin_set_edit unless valid_admin_set_edit?
      invalidate_redirect_to_edit unless valid_redirect_to_edit?

      updated = valid_admin_set_edit? ? @parent_object.update(parent_object_params) : false

      if updated
        @parent_object.minify if valid_redirect_to_edit?
        @parent_object.save!
        queue_parent_metadata_update
        format.html { redirect_to @parent_object, notice: 'Parent object was successfully saved, a full update has been queued.' }
        format.json { render :show, status: :ok, location: @parent_object }
      else
        format.html { render :edit }
        format.json { render json: @parent_object.errors, status: :unprocessable_entity }
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  # DELETE /parent_objects/1
  # DELETE /parent_objects/1.json
  def destroy
    @parent_object.destroy!
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

  def all_metadata_where
    where = { redirect_to: nil }
    admin_set_ids = params[:admin_set]
    admin_set_ids&.compact!
    if !admin_set_ids
      authorize!(:update_metadata, ParentObject)
    else
      where[:admin_set_id] = admin_set_ids
      unless authorize!(:update_metadata, ParentObject)
        admin_set_ids.map { |id| AdminSet.find_by(id: id) }.compact.each.each do |admin_set|
          raise("Access Denied") unless current_ability.can?(:reindex_admin_set, admin_set)
        end
      end
    end
    metadata_source_ids = params[:metadata_source_ids]
    where[:authoritative_metadata_source_id] = metadata_source_ids if metadata_source_ids
    where
  end

  def all_metadata
    UpdateAllMetadataJob.perform_later(0, all_metadata_where)
    respond_to do |format|
      format.html { redirect_back fallback_location: parent_objects_url, notice: 'Parent objects have been queued for metadata update.' }
      format.json { head :no_content }
    end
  end

  def update_metadata
    queue_parent_metadata_update
    respond_to do |format|
      format.html { redirect_back fallback_location: parent_object_url(@parent_object), notice: 'This object has been queued for a metadata update.' }
      format.json { head :no_content }
    end
  end

  def update_manifests
    admin_set_id = params.dig(:admin_set_id)
    admin_set = AdminSet.find(admin_set_id)
    if current_user.viewer(admin_set) || current_user.editor(admin_set)
      UpdateManifestsJob.perform_later(admin_set_id)
      redirect_to admin_set_path(admin_set_id), notice: "IIIF Manifests queued for update. Please check Delayed Job dashboard for status"
    else
      redirect_to admin_set_path(admin_set), alert: "User does not have permission to update Admin Set."
      return false
    end
  end

  def update_digital_objects
    admin_set_id = params.dig(:admin_set_id)
    admin_set = AdminSet.find(admin_set_id)
    if current_user.sysadmin
      UpdateDigitalObjectsJob.perform_later(admin_set_id)
      redirect_to admin_set_path(admin_set_id), notice: "Digital Objects queued for update for #{admin_set.label}. Please check Delayed Job dashboard for status"
    else
      access_denied
    end
  end

  def sync_from_preservica
    queue_parent_sync_from_preservica
    respond_to do |format|
      format.html { redirect_back fallback_location: parent_object_url(@parent_object), notice: 'This object has been queued for synchronization of child objects from Preservica.' }
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
    response = solr.get 'select', params: { q: "id:#{oid}" }
    render json: response["response"]
  end

  private

    def queue_parent_metadata_update
      authorize!(:update, @parent_object)
      @parent_object.metadata_update = true
      @parent_object.setup_metadata_job
    end

    def queue_parent_sync_from_preservica
      authorize!(:update, @parent_object)
      @batch_process = BatchProcess.new(user: current_user,
                                        oid: @parent_object.oid,
                                        batch_action: 'resync with preservica',
                                        csv: CSV.generate do |csv|
                                               csv << ['oid']
                                               csv << [@parent_object.oid.to_s]
                                             end)
      @parent_object.current_batch_connection = @batch_process.batch_connections.build(connectable: @parent_object)
      @batch_process.save!
      @parent_object.current_batch_process = @batch_process
    end

    def valid_admin_set_edit?
      !parent_object_params[:admin_set] || (parent_object_params[:admin_set] && current_user.editor(parent_object_params[:admin_set]))
    end

    def invalidate_admin_set_edit
      @parent_object.errors.add :admin_set, :invalid, message: "cannot be assigned to a set the User cannot edit"
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_parent_object
      @parent_object = ParentObject.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to parent_objects_url, notice: "Parent object, oid: #{params[:id]}, was not found in local database." }
        format.json { head :no_content }
      end
    end

    def set_permission_set
      permission_sets = OpenWithPermission::PermissionSet.all
      @visible_permission_sets = permission_sets.order('label ASC').select do |sets|
        User.with_role(:administrator, sets).include?(current_user) ||
          User.with_role(:sysadmin, sets).include?(current_user)
      end
    end

    def batch_process_of_one
      @batch_process = BatchProcess.new(user: current_user, oid: @parent_object.oid)
      @parent_object.current_batch_connection = @batch_process.batch_connections.build(connectable: @parent_object)
      @batch_process.save!
      @parent_object.current_batch_process = @batch_process
    end

    # rubocop:disable Metrics/LineLength
    def valid_redirect_to_edit?
      !parent_object_params[:redirect_to] || (parent_object_params[:redirect_to]&.match(/\A((http|https):\/\/)?(collections-test.|collections-uat.|collections.)?library.yale.edu\/catalog\//)) if parent_object_params[:redirect_to].present?
    end
    # rubocop:enable Metrics/LineLength

    def invalidate_redirect_to_edit
      @parent_object.errors.add :redirect_to, :invalid, message: "must be in format https://collections.library.yale.edu/catalog/1234567"
    end

    # Only allow a list of trusted parameters through.
    def parent_object_params
      cur_params = params.require(:parent_object).permit(:oid, :admin_set, :project_identifier, :bib, :holding, :item, :barcode, :aspace_uri, :last_ladybird_update, :last_voyager_update,
                                                         :last_aspace_update, :visibility, :last_id_update, :authoritative_metadata_source_id,
                                                         :viewing_direction,
                                                         :permission_set_id,
                                                         :display_layout, :representative_child_oid, :rights_statement, :extent_of_digitization,
                                                         :digitization_note, :digitization_funding_source, :redirect_to, :preservica_uri, :digital_object_source, :preservica_representation_type)
      cur_params[:admin_set] = AdminSet.find_by(key: cur_params[:admin_set]) if cur_params[:admin_set]
      cur_params
    end
end
