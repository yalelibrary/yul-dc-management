# frozen_string_literal: true

class UpdateFulltextStatusJob < ApplicationJob
  queue_as :default

  def default_priority
    50
  end

  # rubocop:disable Metrics/MethodLength
  def perform(batch_process)
    child_limit = 10_000
    current_offset = 0
    current_limit = 0
    child_count = 0
    job_count = 0
    batch_process.oids.each_with_index do |oid, index|
      po = ParentObject.find_by_oid(oid)
      next unless po
      child_count += po.child_objects.count
      current_limit = index - current_offset + 1
      next unless child_count > child_limit
      UpdateFulltextStatusSubJob.perform_later(batch_process, current_offset, current_limit)
      job_count += 1
      current_offset = index
      child_count = 0
    end
    if child_count&.positive?
      UpdateFulltextStatusSubJob.perform_later(batch_process, current_offset, current_limit)
      job_count += 1
    end
    batch_process.batch_processing_event("There were no parents to process.  No work has been completed", "failed") if job_count.zero?
  end
  # rubocop:enable Metrics/MethodLength
end
