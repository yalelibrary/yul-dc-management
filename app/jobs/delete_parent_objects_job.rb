# frozen_string_literal: true

class DeleteParentObjectsJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process)
    batch_process.delete_parent_objects
  end
end
