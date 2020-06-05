# frozen_string_literal: true

class SolrService
  def self.connection
    solr_core = ENV["SOLR_CORE"] ||= "blacklight-core"
    SOLR_BASE_URL = ENV["SOLR_BASE_URL"] ||= "http://localhost:8983/solr"
    RSolr.connect url: "#{SOLR_BASE_URL}/#{solr_core}"
  end
end
