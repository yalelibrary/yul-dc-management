# frozen_string_literal: true

class CreateNewParentJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process)
    batch_process.create_new_parent_csv
  rescue => e
    batch_process.batch_processing_event("Setup job failed to save: #{e.message}", "failed")
  end
end
