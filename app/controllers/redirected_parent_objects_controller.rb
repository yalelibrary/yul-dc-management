# frozen_string_literal: true

class RedirectedParentObjectsController < ApplicationController
  before_action :set_child_object, only: [:show, :edit, :update, :destroy]
  # before_action :set_paper_trail_whodunnit
  # load_and_authorize_resource except: [:new, :create]

  # GET /redirected_parent_objects
  # GET /redirected_parent_objects.json
  def index
    respond_to do |format|
      format.html
      format.json { render json: RedirectedParentObjectDatatable.new(params, view_context: view_context, current_ability: current_ability) }
    end
  end
end
