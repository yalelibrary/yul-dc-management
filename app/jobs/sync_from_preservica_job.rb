# frozen_string_literal: true

class SyncFromPreservicaJob < ApplicationJob
  queue_as :default

  def default_priority
    50
  end

  def perform(batch_process)
    batch_process.sync_from_preservica
  end
end
