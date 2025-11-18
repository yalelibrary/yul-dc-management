# frozen_string_literal: true

class SolrReindexAllJob < ApplicationJob
  queue_as :solr_index

  def self.job_limit
    5000
  end

  def self.solr_batch_limit
    500
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def perform(start_position = 0, current_batch_process = BatchProcess.new)
    solr = SolrService.connection
    current_batch_process.user = User.system_user
    current_batch_process.save!
    # Groups of limit
    parent_objects = ParentObject.order(:oid).offset(start_position).limit(SolrReindexAllJob.job_limit)
    last_job = parent_objects.count < SolrReindexAllJob.job_limit
    if parent_objects.count.positive?
      parent_objects.each_slice(SolrReindexAllJob.solr_batch_limit) do |parent_objects_group|
        child_documents = []
        parent_documents = []

        solr.add(parent_objects_group.reject { |po| !po.should_index? }.map do |parent_object|
          results, child_results = parent_object.to_solr_full_text
          child_documents += child_results unless child_results.nil?
          parent_documents += [results] unless results.nil?
          results
                 rescue => e
                   current_batch_process.batch_processing_event("SolrReindexAllJob failed due to #{e.message} for parent object OID: #{parent_object.oid}.")
                   return nil # if errors will convert parent to nil and compact later removes them
        end.compact)
        solr.commit
        reindex_child_documents(solr, child_documents) unless parent_documents.empty?
      end
      SolrReindexAllJob.perform_later(start_position + parent_objects.count) unless last_job
    end
    SolrService.clean_index_orphans if last_job
    current_batch_process.batch_processing_event("SolrReindexAllJob successfully completed evaluating #{parent_objects.count} parent objects for indexing.", "complete")
  rescue => e
    SolrReindexAllJob.perform_later(start_position + parent_objects.count) unless last_job
    current_batch_process.batch_processing_event("SolrReindexAllJob failed due to #{e.message}", "failed")
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def reindex_child_documents(solr, child_documents)
    child_documents.each_slice(SolrReindexAllJob.solr_batch_limit) do |child_documents_group|
      solr.add(child_documents_group.compact)
      solr.commit
    end
  end
end
