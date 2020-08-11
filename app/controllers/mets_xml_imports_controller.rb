# frozen_string_literal: true

class MetsXmlImportsController < ApplicationController
  before_action :set_mets_xml_import, only: [:show, :edit, :update, :destroy]

  # GET /mets_xml_imports
  # GET /mets_xml_imports.json
  def index
    @mets_xml_imports = MetsXmlImport.all
  end

  # GET /mets_xml_imports/1
  # GET /mets_xml_imports/1.json
  def show; end

  # GET /mets_xml_imports/new
  def new
    @mets_xml_import = MetsXmlImport.new
  end

  # GET /mets_xml_imports/1/edit
  def edit; end

  # POST /mets_xml_imports
  # POST /mets_xml_imports.json
  def create
    @mets_xml_import = MetsXmlImport.new(mets_xml_import_params)

    respond_to do |format|
      if @mets_xml_import.save
        format.html { redirect_to @mets_xml_import, notice: 'METS xml import was successfully created.' }
        format.json { render :show, status: :created, location: @mets_xml_import }
      else
        format.html { render :new }
        format.json { render json: @mets_xml_import.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /mets_xml_imports/1
  # PATCH/PUT /mets_xml_imports/1.json
  def update
    respond_to do |format|
      if @mets_xml_import.update(mets_xml_import_params)
        format.html { redirect_to @mets_xml_import, notice: 'METS xml import was successfully updated.' }
        format.json { render :show, status: :ok, location: @mets_xml_import }
      else
        format.html { render :edit }
        format.json { render json: @mets_xml_import.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mets_xml_imports/1
  # DELETE /mets_xml_imports/1.json
  def destroy
    @mets_xml_import.destroy
    respond_to do |format|
      format.html { redirect_to mets_xml_imports_url, notice: 'METS xml import was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_mets_xml_import
      @mets_xml_import = MetsXmlImport.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def mets_xml_import_params
      params.require(:mets_xml_import).permit(:file)
    end
end
