# frozen_string_literal: true

class SolrService
  def self.connection
    # solr_core = ENV["SOLR_CORE"] ||= "blacklight-core"
    # solr_url = ENV["SOLR_URL"] ||= "http://localhost:8983/solr"
    solr_core = "blacklight-core"
    solr_url = "http://solr:8983/solr"
    RSolr.connect url: "#{solr_url}/#{solr_core}"
  end
end
