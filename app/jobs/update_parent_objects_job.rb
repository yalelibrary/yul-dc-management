# frozen_string_literal: true

class UpdateParentObjectsJob < ApplicationJob
  queue_as :default

  discard_on StandardError, Net::OpenTimeout

  def default_priority
    50
  end

  def perform(batch_process)
    batch_process.update_parent_objects
  end
end
