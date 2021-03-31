module Delayable
  extend ActiveSupport::Concern

  def delayed_jobs
    Delayed::Job.where("handler LIKE ?", "%#{self.class}/#{self.oid}%")
  end

  def setup_metadata_jobs
    Delayed::Job.where("handler LIKE ? AND handler LIKE ?", "job_class: SetupMetadataJob", "%#{self.class}/#{self.oid}%")
  end

  def delayed_jobs_deletion
    self.delayed_jobs.destroy_all
  end
end
