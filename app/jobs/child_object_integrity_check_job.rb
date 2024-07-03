# frozen_string_literal: true

class ChildObjectIntegrityCheckJob < ApplicationJob
  queue_as :default

  def default_priority
    -100
  end

  def perform
    batch_process ||= BatchProcess.create!(batch_action: 'integrity check', user: User.system_user)
    batch_process.integrity_check
  end
end
