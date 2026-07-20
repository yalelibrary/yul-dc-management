# frozen_string_literal: true

class CreateChildOidCsvJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::InterruptErrors
  retry_on GoodJob::InterruptError, attempts: 3 do |job, error|
    batch_process = job.arguments.first
    batch_process&.batch_processing_event(
      "CreateChildOidCsvJob failed: interrupted #{job.executions} times and retry attempts were exhausted: #{error.message}", "failed"
    )
  end
  queue_as :default

  def default_priority
    10
  end

  def perform(batch_process)
    batch_process.child_output_csv
  rescue => e
    batch_process.batch_processing_event("CreateChildOidCsvJob failed to save: #{e.message}", "failed")
  end
end
