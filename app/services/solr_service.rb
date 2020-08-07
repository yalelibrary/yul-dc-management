# frozen_string_literal: true

class SolrService
  def self.connection
    solr_core = ENV["SOLR_CORE"] ||= "blacklight-core"
    solr_base_url = ENV["SOLR_BASE_URL"] ||= "http://localhost:8983/solr"
    RSolr.connect url: File.join(solr_base_url, solr_core)
  end

  def self.delete_all
    self.connection.delete_by_query("*:*")
    self.connection.commit
  end
end
