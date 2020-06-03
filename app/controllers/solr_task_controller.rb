# frozen_string_literal: true

class SolrTaskController < ApplicationController
  def index; end

  def run_task
    ENV["SOLR_CORE"] = "blacklight-core"
    ENV["SOLR_URL"] = "http://solr:8983/solr"
    FixtureIndexingService.index_fixture_data
  end
end
