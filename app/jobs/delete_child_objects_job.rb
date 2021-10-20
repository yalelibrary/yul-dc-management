# frozen_string_literal: true

class DeleteChildObjectsJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process)
    batch_process.delete_child_objects
  end
end
