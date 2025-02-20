# frozen_string_literal: true

class CreateNewParentJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process)
    batch_process.create_new_parent_csv
  end
end
