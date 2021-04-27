class PreservicaIngestsController < ApplicationController
    # GET /preservica_ingest
    # GET /preservica_ingest.json
    def index
      respond_to do |format|
        format.html
        format.json { render json: PreservicaIngestDatatable.new(params, view_context: view_context, current_ability: current_ability) }
      end
    end
end