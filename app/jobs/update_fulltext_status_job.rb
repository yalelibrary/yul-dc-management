# frozen_string_literal: true

class UpdateFulltextStatusJob < ApplicationJob
  queue_as :default

  def default_priority
    50
  end

  def perform(batch_process)
    # split it up by child count
    child_limit = 10_000
    current_offset = 0
    current_limit = 0
    child_count = 0
    batch_process.oids.each_with_index do |oid, index|
      po = ParentObject.find_by_oid(oid)
      unless po
        batch_process.batch_processing_event("Skipping row [#{index + 2}] because unknown parent: #{oid}", 'Unknown Parent')
        next
      end
      child_count += po.child_objects.count
      current_limit = index - current_offset + 1
      next unless child_count > child_limit
      # kick off a job from current_offset to index - current_offset
      UpdateFulltextStatusSubJob.perform_later(batch_process, current_offset, current_limit)
      current_offset = index
      child_count = 0
    end
    UpdateFulltextStatusSubJob.perform_later(batch_process, current_offset, current_limit) if child_count&.positive?
  end
end
