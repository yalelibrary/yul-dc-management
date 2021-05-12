# frozen_string_literal: true

class SolrReindexAllJob < ApplicationJob
  queue_as :solr_index

  def self.job_limit
    5000
  end

  def self.solr_batch_limit
    500
  end

  def perform(start_position = 0)
    solr = SolrService.connection
    # Groups of limit
    parent_objects = ParentObject.order(:oid).offset(start_position).limit(SolrReindexAllJob.job_limit)
    last_job = parent_objects.count < SolrReindexAllJob.job_limit
    if parent_objects.count.positive?
      parent_objects.each_slice(SolrReindexAllJob.solr_batch_limit) do |parent_objects_group|
        child_documents = []
        solr.add(parent_objects_group.map do |parent_object|
          results, child_results = parent_object.to_solr_full_text
          child_documents += child_results unless child_results.nil?
          results
        ).compact) 
        end
        solr.add(child_documents)
        solr.commit
      end
      SolrReindexAllJob.perform_later(start_position + parent_objects.count) unless last_job
    end
    SolrService.clean_index_orphans if last_job
  end
end
