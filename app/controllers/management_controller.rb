# frozen_string_literal: true

class ManagementController < ApplicationController
  def index; end

  def run_task
    FixtureIndexingService.index_fixture_data
  end
end
