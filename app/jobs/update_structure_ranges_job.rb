# frozen_string_literal: true

class UpdateStructureRangesJob < ApplicationJob
  queue_as :default

  def default_priority
    20
  end

  def perform(batch_process)
    batch_process.update_structure_ranges
  rescue => e
    batch_process.batch_processing_event("UpdateStructureRangesJob failed due to #{e.message}", "failed")
  end
end
