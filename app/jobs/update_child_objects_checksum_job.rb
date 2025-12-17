# frozen_string_literal: true

class UpdateChildObjectsChecksumJob < ApplicationJob
  queue_as :default

  discard_on StandardError, Net::OpenTimeout

  def default_priority
    50
  end

  def perform(batch_process)
    batch_process.update_child_objects_checksum
  rescue => e
    batch_process.batch_processing_event("Update child objects checksum job failed to process: #{e.message}", "failed")
  end
end
