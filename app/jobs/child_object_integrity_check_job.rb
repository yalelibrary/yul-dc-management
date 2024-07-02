# frozen_string_literal: true

class ChildObjectIntegrityCheckJob < ApplicationJob
  queue_as :default

  def default_priority
    -100
  end

  # Following the activity stream reader, the batch process is connected in the ActivityStreamreader class. Do we need to do that here, as well as IntegrityCheckable? Or should we just call IntegrityCheckable.integrity_check here in the perform?
  def perform

    @batch_process ||= BatchProcess.create!(batch_action: 'integrity check', user: User.system_user)
    @batch_process.integrity_check
  end
end
