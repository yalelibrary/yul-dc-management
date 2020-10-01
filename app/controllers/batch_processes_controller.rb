class BatchProcessesController < ApplicationController
  def index
    @batch_processes = BatchProcess.all
    @batch_process = BatchProcess.new
  end

  def new
    @batch_process = BatchProcess.new
  end

  def create
    @batch_process = BatchProcess.new(batch_process_params.merge(created_by_id: current_user.uid))
    respond_to do |format|
      if @batch_process.save
        format.html { redirect_to batch_processes_path, notice: "Your records have been retrieved from the MetadataCloud. PTIFF generation, manifest generation and indexing happen in the background." }
      else
        format.html { render :new }
      end
    end
  end

  private

    def batch_process_params
      params.require(:batch_process).permit(:file)
    end

  # Use callbacks to share common setup or constraints between actions.
end
