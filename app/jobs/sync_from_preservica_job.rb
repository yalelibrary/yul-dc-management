# frozen_string_literal: true

class SyncFromPreservicaJob < ApplicationJob
  retry_on RuntimeError, Net::HTTPFatalError, Net::ReadTimeout, FrozenError, PreservicaImageService::PreservicaImageServiceNetworkError, attempts: 3 do |job, exception|
    batch_arg = job.arguments.first
    batch_process_id = batch_arg&.respond_to?(:id) ? batch_arg.id : batch_arg&._aj_globalid&.split('/')&.last&.to_i
    batch_process = BatchProcess.find_by(id: batch_process_id)
    batch_process&.batch_processing_event("Retrying Sync from Preservica - Request error #{exception.message}", "retry")
  end
  queue_as :default

  def default_priority
    50
  end

  def perform(batch_process)
    batch_process.sync_from_preservica
  rescue FrozenError => e
    batch_process.batch_processing_event("Frozen error: #{e.message} at #{e.backtrace.first}", "failed")
    raise
  rescue => e
    batch_process.batch_processing_event("Setup job failed to save: #{e.message}", "failed")
    raise
  end
end
