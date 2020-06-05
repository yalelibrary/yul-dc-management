# frozen_string_literal: true

class SolrService
  def self.connection
    solr_core = ENV["SOLR_CORE"] ||= "blacklight-core"
    solr_base_url = ENV["SOLR_BASE_URL"] ||= "http://localhost:8983/solr"
    RSolr.connect url: URI.join(solr_base_url,solr_core).to_s
  end
end
