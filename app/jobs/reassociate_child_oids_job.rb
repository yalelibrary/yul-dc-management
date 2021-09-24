# frozen_string_literal: true

class ReassociateChildOidsJob < ApplicationJob
  queue_as :default

  def default_priority
    -100
  end

  def perform(batch_process)
    batch_process.reassociate_child_oids
  rescue => e
    batch_process.batch_processing_event("ReassociateChildOidsJob failed due to #{e.message}", "failed")
  end
end
