class SolrTaskController < ApplicationController


  def index
  end

  def run_task
    solr_core = ENV["SOLR_TEST_CORE"] ||= "blacklight-test" 
    solr_url = ENV["SOLR_URL"] ||= "http://localhost:8983/solr" 
    solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
    FixtureIndexingService.index_fixture_data
    redirect_to solr_task_path, notice: "These files are being indexed in the background and will be ready soon."
  end

end
