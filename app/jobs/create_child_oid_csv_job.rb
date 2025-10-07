# frozen_string_literal: true

class CreateChildOidCsvJob < ApplicationJob
  queue_as :default

  def default_priority
    -100
  end

  def perform(batch_process)
    batch_process.child_output_csv
  rescue => e
    batch_process.batch_processing_event("Setup job failed to save: #{e.message}", "failed")
  end
end
