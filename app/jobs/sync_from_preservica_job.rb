# frozen_string_literal: true

class SyncFromPreservicaJob < ApplicationJob
  retry_on RuntimeError, Net::ReadTimeout, attempts: 3
  queue_as :default

  def default_priority
    10
  end

  def perform(batch_process)
    # byebug
    batch_process.sync_from_preservica
  end
end
