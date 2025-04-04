# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class BatchProcessesController < ApplicationController
  before_action :set_batch_process, only: [:show, :edit, :update, :destroy, :download, :download_csv, :download_xml, :download_created, :show_parent, :show_child]
  before_action :set_parent_object, only: [:show_parent, :show_child]
  before_action :find_notes, only: [:show_parent]
  before_action :latest_failure, only: [:show_parent]
  before_action :set_child_object, only: [:show_child]

  # Allows FontAwesome icons to render in header
  content_security_policy(only: [:index, :show]) do |policy|
    policy.script_src :self, :unsafe_inline
    policy.script_src_attr  :self, :unsafe_inline
    policy.script_src_elem  :self, :unsafe_inline
    policy.style_src :self, :unsafe_inline
    policy.style_src_elem :self, :unsafe_inline
  end

  def index
    @batch_process = BatchProcess.new
    # force user to choose action in form
    @batch_process.batch_action = nil

    respond_to do |format|
      format.html
      format.json { render json: BatchProcessDatatable.new(params, view_context: view_context) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: BatchProcessDetailDatatable.new(params, view_context: view_context) }
    end
  end

  def new
    @batch_process = BatchProcess.new
  end

  def create
    @batch_process = BatchProcess.new(batch_process_params.merge(user: current_user))
    respond_to do |format|
      if @batch_process.save
        format.html do
          redirect_to batch_processes_path,
                      notice: "Your job is queued for processing in the background"
        end
      else
        format.html { render :new }
      end
    end
  end

  def download
    @batch_process.csv.nil? ? download_xml : download_csv
  end

  def download_template
    batch_action = params[:batch_action]

    begin

      csv_template = BatchProcess.csv_template(batch_action)

      # Add BOM to force Excel to open correctly
      send_data "\xEF\xBB\xBF" + csv_template,
                type: 'text/csv; charset=utf-8; header=present',
                disposition: "attachment; filename=#{batch_action.parameterize.underscore + '_template.csv'}"
    rescue
      redirect_to batch_processes_path
    end
  end

  def export_parent_sources
    sources = params[:metadata_source_ids]
    redirect_to admin_sets_url, notice: "CSV is being generated. Please visit the Batch Process page to download."
    batch_process = BatchProcess.new(batch_action: 'export all parents by source', user: current_user, file_name: "exported_parent_objects_source.csv")
    batch_process.save!
    ExportAllParentSourcesCsvJob.perform_later(batch_process, sources)
  end

  def export_parent_objects
    # RETURNS ADMIN SET KEY:
    admin_set = params.dig(:admin_set)

    # RETURNS ADMIN SET ID FOR REDIRECTING
    admin_set_id = params.dig(:admin_set_id)
    redirect_to admin_set_path(admin_set_id), notice: "CSV is being generated. Please visit the Batch Process page to download."

    batch_process = BatchProcess.new(batch_action: 'export all parent objects by admin set', user: current_user, file_name: "#{admin_set}_export.csv")
    batch_process.save!
    CreateParentOidCsvJob.perform_later(batch_process, *admin_set_id)
  end

  def download_csv
    # Add BOM to force Excel to open correctly
    send_data "\xEF\xBB\xBF" + @batch_process.csv,
              type: 'text/csv; charset=utf-8; header=present',
              disposition: "attachment; filename=#{@batch_process.file_name}"
  end

  def download_xml
    send_data @batch_process.mets_xml,
              type: 'application/xml',
              disposition: "attachment; filename=#{@batch_process.file_name}"
  end

  def show_parent
    respond_to do |format|
      format.html
      format.json { render json: BatchProcessParentDatatable.new(params, view_context: view_context, batch_process: @batch_process) }
    end
  end

  def show_child; end

  # This is temporary for testing until we enable scheduling
  def trigger_mets_scan
    authorize!(:trigger_mets_scan, ParentObject)
    MetsDirectoryScanJob.perform_later
    respond_to do |format|
      format.html { redirect_to batch_processes_path, notice: 'Mets scan has been triggered.' }
      format.json { head :no_content }
    end
  end

  private

  def set_batch_process
    @batch_process = BatchProcess.find(params[:id])
  end

  def set_parent_object
    @parent_object = ParentObject.find_by(oid: params[:oid])
  end

  def set_child_object
    @child_object = ChildObject.find(params[:child_oid])
    @notes = @child_object.notes_for_batch_process(@batch_process)
    # TODO: Find failure related only to child object?
    @failure = @child_object.latest_failure(@batch_process)
  end

  def find_notes
    @notes = @parent_object.notes_for_batch_process(@batch_process) if @parent_object
  end

  def latest_failure
    @latest_failure = @parent_object.latest_failure(@batch_process) if @parent_object
  end

  def batch_process_params
    params.require(:batch_process).permit(:file, :batch_action)
  end
end
# rubocop:enable Metrics/ClassLength
