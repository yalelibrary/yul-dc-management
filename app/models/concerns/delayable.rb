# frozen_string_literal: true

module Delayable
  extend ActiveSupport::Concern

  def delayed_jobs
    GoodJob::Job.where("serialized_params['arguments'] => 'parent_object' LIKE ? or serialized_params['arguments'] => 'parent_object' LIKE ?", "%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def setup_metadata_jobs
    GoodJob::Job.where("job_class LIKE ? AND (job_class LIKE ? or job_class LIKE ?)", "%job_class: %SetupMetadataJob%", "%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def solr_index_jobs
    GoodJob::Job.where("job_class LIKE ? AND (job_class LIKE ? or job_class LIKE ?)", "%job_class: %SolrIndexJob%", "%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def queued_solr_index_jobs
    GoodJob::Job.where("locked_by IS NULL AND job_class LIKE ? AND (job_class LIKE ? or job_class LIKE ?)", "%job_class: %SolrIndexJob%", "%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def solr_reindex_jobs
    GoodJob::Job.where("job_class LIKE ?", "%job_class: SolrReindexAllJob%")
  end

  module_function :solr_reindex_jobs

  def delayed_jobs_deletion
    delayed_jobs.destroy_all
  end
end
