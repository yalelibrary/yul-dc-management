# frozen_string_literal: true

module Delayable
  extend ActiveSupport::Concern

  def delayed_jobs
    Delayed::Job.where("handler LIKE ? or handler LIKE ?", "%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def setup_metadata_jobs
    Delayed::Job.where("handler LIKE ? AND (handler LIKE ? or handler LIKE ?)", "%job_class: %SetupMetadataJob%", "%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def solr_index_jobs
    Delayed::Job.where("handler LIKE ? AND (handler LIKE ? or handler LIKE ?)", "%job_class: %SolrIndexJob%", "%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def queued_solr_index_jobs
    Delayed::Job.where("locked_by IS NULL AND handler LIKE ? AND (handler LIKE ? or handler LIKE ?)", "%job_class: %SolrIndexJob%", "%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def solr_reindex_jobs
    Delayed::Job.where("handler LIKE ?", "%job_class: SolrReindexAllJob%")
  end

  module_function :solr_reindex_jobs

  def delayed_jobs_deletion
    delayed_jobs.destroy_all
  end
end
