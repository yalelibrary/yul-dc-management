# frozen_string_literal: true

class BatchProcessesController < ApplicationController
  before_action :set_batch_process, only: [:show, :edit, :update, :destroy, :download, :download_csv, :download_xml, :show_parent, :show_child]
  before_action :set_parent_object, only: [:show_parent, :show_child]
  before_action :find_notes, only: [:show_parent]
  before_action :latest_failure, only: [:show_parent]
  before_action :set_child_object, only: [:show_child]

  def index
    @batch_process = BatchProcess.new

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
                      notice: "Your records have been retrieved from the MetadataCloud. PTIFF generation, manifest generation and indexing happen in the background."
        end
      else
        format.html { render :new }
      end
    end
  end

  def download
    @batch_process.csv.nil? ? download_xml : download_csv
  end

  def download_csv
    send_data @batch_process.csv,
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
      format.json { render json: BatchProcessParentDatatable.new(params, view_context: view_context) }
    end
  end

  def show_child; end

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
      @failures = @child_object.latest_failure(@batch_process)
    end

    def find_notes
      @notes = @parent_object.notes_for_batch_process(@batch_process) if @parent_object
    end

    def latest_failure
      @latest_failure = @parent_object.latest_failure(@batch_process) if @parent_object
    end

    def batch_process_params
      params.require(:batch_process).permit(:file)
    end
end
