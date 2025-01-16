# frozen_string_literal: true

class ReassociateChildOidsJob < ApplicationJob
  queue_as :default

  def default_priority
    50
  end

  def perform(batch_process, start_index = 0)
    begin
      index = batch_process.reassociate_child_oids(start_index)
      if index > 50
        ReassociateChildOidsJob.perform_later(batch_process, index)
      end
    rescue => e
      batch_process.batch_processing_event("ReassociateChildOidsJob failed due to #{e.message}", "failed")
    end
  end
end
