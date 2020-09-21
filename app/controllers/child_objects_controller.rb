# frozen_string_literal: true

class ChildObjectsController < ApplicationController
  before_action :set_child_object, only: [:show, :edit, :update, :destroy]

  # GET /child_objects
  # GET /child_objects.json
  def index
    @child_objects = ChildObject.page params[:page]
  end

  # GET /child_objects/1
  # GET /child_objects/1.json
  def show; end

  # GET /child_objects/new
  def new
    @child_object = ChildObject.new
  end

  # GET /child_objects/1/edit
  def edit; end

  # POST /child_objects
  # POST /child_objects.json
  def create
    @child_object = ChildObject.new(child_object_params)

    respond_to do |format|
      if @child_object.save
        format.html { redirect_to @child_object, notice: 'Child object was successfully created.' }
        format.json { render :show, status: :created, location: @child_object }
      else
        format.html { render :new }
        format.json { render json: @child_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /child_objects/1
  # PATCH/PUT /child_objects/1.json
  def update
    respond_to do |format|
      if @child_object.update(child_object_params)
        format.html { redirect_to @child_object, notice: 'Child object was successfully updated.' }
        format.json { render :show, status: :ok, location: @child_object }
      else
        format.html { render :edit }
        format.json { render json: @child_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /child_objects/1
  # DELETE /child_objects/1.json
  def destroy
    @child_object.destroy
    respond_to do |format|
      format.html { redirect_to child_objects_url, notice: 'Child object was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_child_object
      @child_object = ChildObject.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def child_object_params
      params.require(:child_object).permit(:oid, :caption, :width, :height, :order, :parent_object_oid)
    end
end
