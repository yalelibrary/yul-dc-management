# frozen_string_literal: true

class BatchProcessesController < ApplicationController
  before_action :set_batch_process, only: [:show, :edit, :update, :destroy, :download, :download_csv, :download_xml, :parent_objects]
  before_action :set_parent_object_oids, only: [:parent_objects]

  def index
    @batch_process = BatchProcess.new

    respond_to do |format|
      format.html
      format.json { render json: BatchProcessDatatable.new(params, view_context: view_context) }
    end
  end

  def show; end

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

  def parent_objects
  end



  private

    def set_batch_process
      @batch_process = BatchProcess.find(params[:id])
    end

    def set_parent_object_oids
      @parent_object_connections = BatchConnection.where(batch_process_id: @batch_process.id, connectable_type: "ParentObject")
      @parent_object_oids = @parent_object_connections.map { |pc| pc.connectable_id }
    end

    def batch_process_params
      params.require(:batch_process).permit(:file)
    end
end
