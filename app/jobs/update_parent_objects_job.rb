# frozen_string_literal: true

class UpdateParentObjectsJob < ApplicationJob
  queue_as :default

  discard_on StandardError, Net::OpenTimeout

  def default_priority
    50
  end

  def perform(batch_process, start_index = 0)
    index = batch_process.update_parent_objects(start_index)
    UpdateParentObjectsJob.perform_later(batch_process, index) if !index.nil? && index != -1 && index > BatchProcess::BATCH_LIMIT
  end
end
