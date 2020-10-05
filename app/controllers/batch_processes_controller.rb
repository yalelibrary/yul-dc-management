# frozen_string_literal: true

class BatchProcessesController < ApplicationController
  def index
    @batch_processes = BatchProcess.all
    @batch_process = BatchProcess.new
  end

  def new
    @batch_process = BatchProcess.new
  end

  def create
    @batch_process = BatchProcess.new(batch_process_params.merge(user_id: current_user.id))
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

  private

    def batch_process_params
      params.require(:batch_process).permit(:file)
    end
end
