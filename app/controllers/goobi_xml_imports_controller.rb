# frozen_string_literal: true

class GoobiXmlImportsController < ApplicationController
  before_action :set_goobi_xml_import, only: [:show, :edit, :update, :destroy]

  # GET /goobi_xml_imports
  # GET /goobi_xml_imports.json
  def index
    @goobi_xml_imports = GoobiXmlImport.all
  end

  # GET /goobi_xml_imports/1
  # GET /goobi_xml_imports/1.json
  def show; end

  # GET /goobi_xml_imports/new
  def new
    @goobi_xml_import = GoobiXmlImport.new
  end

  # GET /goobi_xml_imports/1/edit
  def edit; end

  # POST /goobi_xml_imports
  # POST /goobi_xml_imports.json
  def create
    @goobi_xml_import = GoobiXmlImport.new(goobi_xml_import_params)

    respond_to do |format|
      if @goobi_xml_import.save
        @goobi_xml_import.refresh_metadata_cloud
        format.html { redirect_to @goobi_xml_import, notice: 'Goobi xml import was successfully created.' }
        format.json { render :show, status: :created, location: @goobi_xml_import }
      else
        format.html { render :new }
        format.json { render json: @goobi_xml_import.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /goobi_xml_imports/1
  # PATCH/PUT /goobi_xml_imports/1.json
  def update
    respond_to do |format|
      if @goobi_xml_import.update(goobi_xml_import_params)
        format.html { redirect_to @goobi_xml_import, notice: 'Goobi xml import was successfully updated.' }
        format.json { render :show, status: :ok, location: @goobi_xml_import }
      else
        format.html { render :edit }
        format.json { render json: @goobi_xml_import.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /goobi_xml_imports/1
  # DELETE /goobi_xml_imports/1.json
  def destroy
    @goobi_xml_import.destroy
    respond_to do |format|
      format.html { redirect_to goobi_xml_imports_url, notice: 'Goobi xml import was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_goobi_xml_import
      @goobi_xml_import = GoobiXmlImport.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def goobi_xml_import_params
      params.require(:goobi_xml_import).permit(:file)
    end
end
