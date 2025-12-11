# frozen_string_literal: true

class UpdateParentObjectsJob < ApplicationJob
  queue_as :default

  discard_on StandardError, Net::OpenTimeout

  def default_priority
    50
  end

  def perform(batch_process)
    batch_process.update_parent_objects
  rescue ArgumentError => e
    if e.message.include?("invalid byte sequence in UTF-8")
      batch_process.batch_processing_event("Setup job failed: Invalid UTF-8 encoding detected in metadata.", "failed")
    else
      batch_process.batch_processing_event("Setup job failed to save: #{e.message}", "failed")
    end
  rescue => e
    batch_process.batch_processing_event("Setup job failed to save: #{e.message}", "failed")
  end
end
