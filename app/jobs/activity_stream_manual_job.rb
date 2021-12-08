# frozen_string_literal: true

# A separate job is needed for manual run, or it will enqueue itself again after it has finished
class ActivityStreamManualJob < ApplicationJob
  def perform
    ActivityStreamReader.update unless ActivityStreamLog.where(status: "Running").exists?
  end
end
