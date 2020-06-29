# frozen_string_literal: true

class ManagementController < ApplicationController
  def index; end

  def index_to_solr
    @metadata_source = FixtureIndexingService.index_fixture_data(params[:metadata_source])
    redirect_to management_index_path
    flash[:notice] = "Your files have been indexed to Solr."
  end

  def update_database
    FixtureParsingService.find_source_ids
    redirect_to management_index_path
    flash[:notice] = "The database has been updated."
  end

  def update_from_activity_stream
    ActivityStreamReader.update
    redirect_to management_index_path
    flash[:notice] = "Updated from Activity Stream."
  end
end
