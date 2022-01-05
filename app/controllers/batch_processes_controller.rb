# frozen_string_literal: true

class BatchProcessesController < ApplicationController
  before_action :set_batch_process, only: [:show, :edit, :update, :destroy, :download, :download_csv, :download_xml, :download_created, :show_parent, :show_child]
  before_action :set_parent_object, only: [:show_parent, :show_child]
  before_action :find_notes, only: [:show_parent]
  before_action :latest_failure, only: [:show_parent]
  before_action :set_child_object, only: [:show_child]

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
