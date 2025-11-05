# frozen_string_literal: true

module Delayable
  extend ActiveSupport::Concern

  def delayed_jobs
    GoodJob::Job.where("serialized_params->'arguments'->0->>'_aj_globalid' LIKE ? or serialized_params->'arguments'->0->>'_aj_globalid' LIKE ?", "%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def setup_metadata_jobs
    GoodJob::Job.where("job_class LIKE ? AND (serialized_params->'arguments'->0->>'_aj_globalid' LIKE ? or serialized_params->'arguments'->0->>'_aj_globalid' LIKE ?)", "%SetupMetadataJob%",
"%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def solr_index_jobs
    GoodJob::Job.where("job_class LIKE ? AND (serialized_params->'arguments'->0->>'_aj_globalid' LIKE ? or serialized_params->'arguments'->0->>'_aj_globalid' LIKE ?)", "%SolrIndexJob%",
"%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def queued_solr_index_jobs
    GoodJob::Job.where("finished_at IS NULL AND job_class LIKE ? AND (serialized_params->'arguments'->0->>'_aj_globalid' LIKE ? or serialized_params->'arguments'->0->>'_aj_globalid' LIKE ?)",
"%SolrIndexJob%", "%#{self.class}/#{oid}", "%#{self.class}/#{oid}\n%")
  end

  def active_solr_reindex_jobs
    GoodJob::Job.where("finished_at IS NULL AND job_class LIKE ?", "%SolrReindexAllJob%")
  end

  module_function :active_solr_reindex_jobs

  def delayed_jobs_deletion
    delayed_jobs.destroy_all
  end
end
