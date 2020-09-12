# frozen_string_literal: true

class OidImportsController < ApplicationController
  def index
    @oid_imports = OidImport.all
    @oid_import = OidImport.new
  end

  def new
    @oid_import = OidImport.new
  end

  def create
    @oid_import = OidImport.new(oid_import_params)
    respond_to do |format|
      if @oid_import.save
        format.html { redirect_to oid_imports_path, notice: "Your records have been retrieved from the MetadataCloud. PTIFF generation, manifest generation and indexing happen in the background." }
      else
        format.html { render :new }
      end
    end
  end

  private

    def oid_import_params
      params.require(:oid_import).permit(:file)
    end
end
