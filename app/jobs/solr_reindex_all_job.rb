# frozen_string_literal: true

class SolrReindexAllJob < ApplicationJob
  queue_as :default

  def perform
    solr = SolrService.connection
    # Groups of 500
    ParentObject.find_in_batches do |group|
      solr.add(group.map(&:to_solr).compact)
      solr.commit
    end
    SolrService.clean_index_orphans
  end
end
