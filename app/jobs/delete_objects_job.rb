# frozen_string_literal: true

class DeleteObjectsJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process)
    batch_process.delete_objects
  end
end
