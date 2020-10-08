# frozen_string_literal: true

class BatchProcessEventsController < ApplicationController
  before_action :set_batch_process_event, only: [:show, :destroy]

  # GET /batch_process_events
  # GET /batch_process_events.json
  def index
    @batch_process_events = BatchProcessEvent.all
  end

  # GET /batch_process_events/1
  # GET /batch_process_events/1.json
  def show; end

  # DELETE /batch_process_events/1
  # DELETE /batch_process_events/1.json
  def destroy
    @batch_process_event.destroy
    respond_to do |format|
      format.html { redirect_to batch_process_events_url, notice: 'Batch process event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_batch_process_event
      @batch_process_event = BatchProcessEvent.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def batch_process_event_params
      params.require(:batch_process_event).permit(
        :batch_process_id,
        :parent_object_oid,
        :queued,
        :metadata_fetched,
        :child_records_created,
        :ptiff_jobs_created,
        :iiif_manifest_saved,
        :indexed_to_solr
      )
    end
end
