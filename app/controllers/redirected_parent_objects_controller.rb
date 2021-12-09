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

  # GET /redirected_parent_objects/1
  # GET /redirected_parent_objects/1.json
  def show; end

  # GET /redirected_parent_objects/new
  def new; end

  # GET /redirected_parent_objects/1/edit
  def edit; end

  # POST /redirected_parent_objects
  # POST /redirected_parent_objects.json
  def create; end

  # PATCH/PUT /redirected_parent_objects/1
  # PATCH/PUT /redirected_parent_objects/1.json
  def update; end

  # DELETE /redirected_parent_objects/1
  # DELETE /redirected_parent_objects/1.json
  def destroy; end
end
