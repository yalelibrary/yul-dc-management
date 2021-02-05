# frozen_string_literal: true

class ReassociateChildOidsJob < ApplicationJob
  queue_as :default

  def default_priority
    -100
  end

  def perform(batch_process)
    batch_process.reassociate_child_oids
  end
end
