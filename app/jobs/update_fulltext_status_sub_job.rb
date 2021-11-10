# frozen_string_literal: true

class UpdateFulltextStatusSubJob < ApplicationJob
  queue_as :default

  def default_priority
    50
  end

  def perform(batch_process, offset, limit)
    batch_process.update_fulltext_status(offset, limit)
  end
end
