# frozen_string_literal: true

class DeleteParentObjectsJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process)
    batch_process.delete_parent_objects
  rescue => e
    batch_process.batch_processing_event("Setup job failed to save: #{e.message}", "failed")
  end
end
