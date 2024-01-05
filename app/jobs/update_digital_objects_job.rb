# frozen_string_literal: true

class UpdateDigitalObjectsJob < ApplicationJob
  queue_as :metadata

  def self.job_limit
    5000
  end

  # rubocop:disable Style/OptionalArguments
  # rubocop:disable Lint/UselessAssignment
  def perform(admin_set_id, start_position = 0)
    parent_objects = ParentObject.where(admin_set_id: admin_set_id).order(:oid).offset(start_position).limit(UpdateDigitalObjectsJob.job_limit)
    last_job = parent_objects.count < UpdateDigitalObjectsJob.job_limit
    return unless parent_objects.count.positive? # stop if nothing is found
    parent_objects.each do |po|
      po.digital_object_check(true)
    end
    UpdateDigitalObjectsJob.perform_later(admin_set_id, start_position + parent_objects.count) unless last_job
  end
  # rubocop:enable Style/OptionalArguments
  # rubocop:enable Lint/UselessAssignment
end
