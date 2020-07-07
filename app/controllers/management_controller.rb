# frozen_string_literal: true

class ManagementController < ApplicationController
  def index
    @oid_import = OidImport.new
  end

  def index_to_solr
    @ms = FixtureIndexingService.index_fixture_data(params[:ms])
    redirect_to root_path
    flash[:notice] = "Your files are being indexed in the background and will be ready soon."
  end
end
