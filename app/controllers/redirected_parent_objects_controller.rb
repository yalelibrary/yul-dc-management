# frozen_string_literal: true

class RedirectedParentObjectsController < ApplicationController

  # GET /redirected_parent_objects
  # GET /redirected_parent_objects.json
  def index
    respond_to do |format|
      format.html
      format.json { render json: RedirectedParentObjectDatatable.new(params, view_context: view_context, current_ability: current_ability) }
    end
  end
end
