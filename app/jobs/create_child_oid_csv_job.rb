# frozen_string_literal: true

class CreateChildOidCsvJob < ApplicationJob
  retry_on GoodJob::InterruptError, attempts: 3
  queue_as :default

  def default_priority
    -100
  end

  def perform(batch_process)
    batch_process.child_output_csv
  rescue => e
    batch_process.batch_processing_event("CreateChildOidCsvJob failed to save: #{e.message}", "failed")
  end
end
