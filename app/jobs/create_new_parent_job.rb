# frozen_string_literal: true

class CreateNewParentJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process, start_index = 0)
    index = batch_process.create_new_parent_csv(start_index)
    CreateNewParentJob.perform_later(batch_process, index) if !index.nil? && index != -1 && index > BatchProcess::BATCH_LIMIT
  end
end
