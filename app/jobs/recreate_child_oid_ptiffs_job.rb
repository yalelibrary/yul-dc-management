# frozen_string_literal: true

class RecreateChildOidPtiffsJob < ApplicationJob
  queue_as :default

  def default_priority
    9
  end

  def perform(batch_process, start_index = 0)
    index = batch_process.recreate_child_oid_ptiffs(start_index)
    RecreateChildOidPtiffsJob.perform_later(batch_process, index) if index > BatchProcess::BATCH_LIMIT
  end
end
