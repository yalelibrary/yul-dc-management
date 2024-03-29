# frozen_string_literal: true

class UpdateAllMetadataJob < ApplicationJob
  queue_as :metadata

  def self.job_limit
    5000
  end

  def perform(start_position = 0, where = 'redirect_to: nil')
    parent_objects = ParentObject.where(where).order(:oid).offset(start_position).limit(UpdateAllMetadataJob.job_limit)
    last_job = parent_objects.count < UpdateAllMetadataJob.job_limit
    return unless parent_objects.count.positive? # stop if nothing is found
    parent_objects.each do |po|
      po.metadata_update = true
      po.setup_metadata_job
    end
    UpdateAllMetadataJob.perform_later(start_position + parent_objects.count, where) unless last_job
  end
end
