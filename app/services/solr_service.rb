# frozen_string_literal: true

class SolrService
  def self.connection
    solr_core = ENV["SOLR_CORE"] ||= "blacklight-core"
    solr_base_url = ENV["SOLR_BASE_URL"] ||= "http://localhost:8983/solr"
    RSolr.connect url: File.join(solr_base_url, solr_core)
  end

  def self.delete_all
    connection.delete_by_query("*:*")
    connection.commit
  end

  # Heavily influenced by https://github.com/sunspot/sunspot
  #
  # ==== Options (passed as a hash)
  #
  # batch_size<Integer>:: Override default batch size with which to load records.
  #
  # ==== Returns
  #
  # Array:: Collection of IDs that exist in Solr but not in the database
  def self.solr_index_orphans(opts = {})
    batch_size = opts[:batch_size] || 500

    solr_page = 0
    solr_ids = []
    while (solr_page = solr_page.next)
      search = connection.paginate(solr_page, batch_size, "select", params: { q: 'id:*', fl: 'id' })
      ids = (search&.[]('response')&.[]('docs')&.map { |r| r.values })&.flatten
      break if ids.empty?
      solr_ids.concat(ids.map(&:to_i))
    end

    solr_ids - ParentObject.pluck(:oid)
  end

  # Heavily influenced by https://github.com/sunspot/sunspot
  # Find IDs of records of this class that are indexed in Solr but do not
  # exist in the database, and remove them from Solr. Under normal
  # circumstances, this should not be necessary; this method is provided
  # in case something goes wrong.
  #
  # ==== Options (passed as a hash)
  #
  # batch_size<Integer>:: Override default batch size with which to load records
  #
  def self.clean_index_orphans(opts = {})
    orphans = solr_index_orphans(opts)
    connection.delete_by_id(orphans)
    connection.commit
  end
end
