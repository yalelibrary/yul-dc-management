# frozen_string_literal: true

class SyncFromPreservicaJob < ApplicationJob
  retry_on RuntimeError, Net::HTTPFatalError, Net::ReadTimeout, attempts: 3
  queue_as :default

  def default_priority
    10
  end

  def perform(batch_process)
    batch_process.sync_from_preservica
  rescue FrozenError => e
    batch_process.batch_processing_event("Frozen error: #{e.message} at #{e.backtrace.first}", "failed")
  rescue => e
    batch_process.batch_processing_event("Setup job failed to save: #{e.message}", "failed")
  end
end
