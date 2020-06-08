# frozen_string_literal: true

class ManagementController < ApplicationController
  def index; end

  def run_task
    FixtureIndexingService.index_fixture_data
    redirect_to management_index_path
    flash[:notice] = "These files are being indexed in the background and will be ready soon."
  end
end
