# frozen_string_literal: true

class UpdateFulltextStatusJob < ApplicationJob
  queue_as :default

  def default_priority
    50
  end

  def perform(batch_process)
    batch_process.update_fulltext_status
  end
end
