# frozen_string_literal: true

class UpdateChildObjectsJob < ApplicationJob
  queue_as :default

  discard_on StandardError, Net::OpenTimeout

  def default_priority
    50
  end

  def perform(batch_process)
    batch_process.update_child_objects_caption
  rescue => e
    batch_process.batch_processing_event("Setup job failed to save: #{e.message}", "failed")
  end
end
