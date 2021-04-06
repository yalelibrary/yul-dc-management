# frozen_string_literal: true

module Delayable
  extend ActiveSupport::Concern

  def delayed_jobs
    Delayed::Job.where("handler LIKE ?", "%#{self.class}/#{oid}%")
  end

  def setup_metadata_jobs
    Delayed::Job.where("handler LIKE ? AND handler LIKE ?", "job_class: %SetupMetadataJob%", "%#{self.class}/#{oid}%")
  end

  def delayed_jobs_deletion
    delayed_jobs.destroy_all
  end
end
