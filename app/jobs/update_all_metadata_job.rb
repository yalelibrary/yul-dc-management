# frozen_string_literal: true

class UpdateAllMetadataJob < ApplicationJob
  queue_as :metadata

  def self.job_limit
    5000
  end

  def perform(start_position = 0)
    parent_objects = ParentObject.order(:oid).offset(start_position).limit(UpdateAllMetadataJob.job_limit)
    last_job = parent_objects.count < UpdateAllMetadataJob.job_limit
    if parent_objects.count.positive?
      parent_objects.each do |po|
        po.metadata_update = true
        po.setup_metadata_job
      end
      UpdateAllMetadataJob.perform_later(start_position + parent_objects.count) unless last_job
    end
  end
end
