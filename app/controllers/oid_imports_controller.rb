class OidImportsController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, with: :show_errors

  def index
    @oid_imports = OidImport.all
  end

  def new
    @oid_import = OidImport.new
  end

  def create
    @oid_import = OidImport.new(oid_import_params)
    respond_to do |format|
      if @oid_import.save
        @oid_import.refresh_metadata_cloud
        format.html { redirect_to management_index_path, notice: "Your records are being imported" }
      else
        format.html { render :new }
      end
    end
  end

  private

    def oid_import_params
      params.require(:oid_import).permit(:file)
    end

    def show_errors(exception)
      exception.record.new_record?
      redirect_to management_index_path, notice: "A validation error has occurred"
    end

end