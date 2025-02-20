# frozen_string_literal: true

class RecreateChildOidPtiffsJob < ApplicationJob
  queue_as :default

  def default_priority
    9
  end

  def perform(batch_process)
    batch_process.recreate_child_oid_ptiffs
  end
end
