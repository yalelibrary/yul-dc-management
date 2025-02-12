# frozen_string_literal: true

class SolrService
  def self.connection
    solr_core = ENV["SOLR_CORE"] ||= "blacklight-core"
    solr_base_url = ENV["SOLR_URL"] ||= "http://localhost:8983/solr"
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
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def self.solr_index_orphans(opts = {})
    batch_size = opts[:batch_size] || 500

    solr_page = 0
    solr_ids = []
    while (solr_page = solr_page.next)
      search = connection.paginate(solr_page, batch_size, "select", params: { q: 'oid_ssi:[* TO *]', fl: 'id' })
      ids = (search&.[]('response')&.[]('docs')&.map { |r| r.values })&.flatten
      break if ids.empty?
      solr_ids.concat(ids.map(&:to_i))
    end

    solr_ids - ParentObject.pluck(:oid)
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

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

  # Creates a new field type to update schema of already create solr index
  def self.add_field_type(name, type, index_analyzer, query_analyzer)
    post_to_schema(
      "add-field-type": {
        "name": name,
        "class": type,
        "indexAnalyzer": index_analyzer,
        "queryAnalyzer": query_analyzer
      }
    )
  end

  # Creates a new field type to update schema of already create solr index
  def self.replace_field_type(name, type, index_analyzer, query_analyzer)
    post_to_schema(
      "replace-field-type": {
        "name": name,
        "class": type,
        "indexAnalyzer": index_analyzer,
        "queryAnalyzer": query_analyzer
      }
    )
  end

  # Creates a new field type to update schema of already create solr index
  def self.replace_dynamic_field(name, type, indexed, stored, multi_value)
    post_to_schema(
      "replace-dynamic-field": {
        "name": name,
        "type": type,
        "indexed": indexed,
        "multiValued": multi_value,
        "stored": stored
      }
    )
  end

  # Creates a new field type to update schema of already create solr index
  def self.add_dynamic_field(name, type, indexed, stored, multi_value)
    post_to_schema(
      "add-dynamic-field": {
        "name": name,
        "type": type,
        "indexed": indexed,
        "multiValued": multi_value,
        "stored": stored
      }
    )
  end

  # Creates a new copy field type to update managed schema
  def self.add_copy_field(source, dest)
    post_to_schema(
      "add-copy-field": {
        "source": source,
        "dest": dest
      }
    )
  end

  # Deletes a copy field type to update managed schema
  def self.delete_copy_field(source, dest)
    post_to_schema(
      "delete-copy-field": {
        "source": source,
        "dest": dest
      }
    )
  end

  def self.get_file(file)
    connection.connection.get("admin/file?file=#{file}")
  end

  def self.post_to_schema(data)
    connection.connection.post('schema') do |req|
      req.body = data.to_json
      req.headers['Content-Type'] = 'application/json'
    end
  end
end
