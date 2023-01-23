# frozen_string_literal: true

class UpdateManifestsJob < ApplicationJob
  queue_as :metadata

  def self.job_limit
    5000
  end

  # rubocop:disable Style/OptionalArguments
  def perform(admin_set_id, start_position = 0)
    visibilities = ["Public", "Yale Community Only"]
    parent_objects = ParentObject.where(admin_set_id: admin_set_id, visibility: visibilities).where.not(child_object_count: 0).order(:oid).offset(start_position).limit(UpdateManifestsJob.job_limit)
    last_job = parent_objects.count < UpdateManifestsJob.job_limit
    return unless parent_objects.count.positive? # stop if nothing is found
    parent_objects.each do |po|
      GenerateManifestJob.perform_later(po)
    end
    UpdateManifestsJob.perform_later(admin_set_id, start_position + parent_objects.count) unless last_job
  end
  # rubocop:enable Style/OptionalArguments
end
