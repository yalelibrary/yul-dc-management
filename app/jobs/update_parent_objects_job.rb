# frozen_string_literal: true

class UpdateParentObjectsJob < ApplicationJob
  queue_as :default

  discard_on StandardError, Net::OpenTimeout

  def default_priority
    50
  end

  def perform(batch_process, start_index = 0)
    index = batch_process.update_parent_objects(start_index)
    if index > 50
      UpdateParentObjectsJob.perform_later(batch_process, index)
    end
  end
end
