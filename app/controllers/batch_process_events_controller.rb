class BatchProcessEventsController < ApplicationController
  before_action :set_batch_process_event, only: [:show, :edit, :update, :destroy]

  # GET /batch_process_events
  # GET /batch_process_events.json
  def index
    @batch_process_events = BatchProcessEvent.all
  end

  # GET /batch_process_events/1
  # GET /batch_process_events/1.json
  def show
  end

  # GET /batch_process_events/new
  def new
    @batch_process_event = BatchProcessEvent.new
  end

  # GET /batch_process_events/1/edit
  def edit
  end

  # POST /batch_process_events
  # POST /batch_process_events.json
  def create
    @batch_process_event = BatchProcessEvent.new(batch_process_event_params)

    respond_to do |format|
      if @batch_process_event.save
        format.html { redirect_to @batch_process_event, notice: 'Batch process event was successfully created.' }
        format.json { render :show, status: :created, location: @batch_process_event }
      else
        format.html { render :new }
        format.json { render json: @batch_process_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /batch_process_events/1
  # PATCH/PUT /batch_process_events/1.json
  def update
    respond_to do |format|
      if @batch_process_event.update(batch_process_event_params)
        format.html { redirect_to @batch_process_event, notice: 'Batch process event was successfully updated.' }
        format.json { render :show, status: :ok, location: @batch_process_event }
      else
        format.html { render :edit }
        format.json { render json: @batch_process_event.errors, status: :unprocessable_entity }
      end
    end
  end

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
      params.require(:batch_process_event).permit(:batch_process_id, :parent_object_id, :queued, :metadata_fetched, :child_records_created, :ptiff_jobs_created, :iiif_manifest_saved, :indexed_to_solr)
    end
end
