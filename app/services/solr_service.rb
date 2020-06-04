# frozen_string_literal: true

class SolrService
  def self.connection
    # solr_core = ENV["SOLR_CORE"] ||= "blacklight-core"
    # solr_host = ENV["SOLR_HOST"] ||= "http://localhost:8983/solr"
    solr_core = "blacklight-core"
    solr_host = "http://solr:8983/solr"
    RSolr.connect url: "#{solr_host}/#{solr_core}"
  end
end
