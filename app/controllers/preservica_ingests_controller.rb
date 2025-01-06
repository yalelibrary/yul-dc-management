# frozen_string_literal: true

class PreservicaIngestsController < ApplicationController
  # Allows FontAwesome icons to render on index
  content_security_policy(only: :index) do |policy|
    policy.script_src :self, :unsafe_inline
    policy.script_src_attr  :self, :unsafe_inline
    policy.script_src_elem  :self, :unsafe_inline
    policy.style_src :self, :unsafe_inline
    policy.style_src_elem :self, :unsafe_inline
  end

  # GET /preservica_ingest
  # GET /preservica_ingest.json
  def index
    respond_to do |format|
      format.html
      format.json { render json: PreservicaIngestDatatable.new(params, view_context: view_context, current_ability: current_ability) }
    end
  end
end
