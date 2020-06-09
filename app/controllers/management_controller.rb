# frozen_string_literal: true

class ManagementController < ApplicationController
  def index; end

  def index_to_solr
    @metadata_source = FixtureIndexingService.index_fixture_data(params[:metadata_source])
    redirect_to management_index_path
    flash[:notice] = "Your files are being indexed in the background and will be ready soon."
  end
end
