# frozen_string_literal: true

class GenerateOutputCsvJob < ApplicationJob
  queue_as :default

  def perform(batch_process)
    batch_process.output_csv
  rescue => e
    parent_object.processing_event("Setup job failed to save: #{e.message}", "failed", current_batch_process, current_batch_connection)
    raise # this reraises the error after we document it
  end
end
