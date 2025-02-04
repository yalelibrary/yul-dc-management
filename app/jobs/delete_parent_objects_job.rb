# frozen_string_literal: true

class DeleteParentObjectsJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process, start_index = 0)
    index = batch_process.delete_parent_objects(start_index)
    DeleteParentObjectsJob.perform_later(batch_process, index) if !index.nil? && index != -1 && index > BatchProcess::BATCH_LIMIT
  end
end
