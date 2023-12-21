# frozen_string_literal: true

class ActivityStreamJob < ApplicationJob
  def perform
    ActivityStreamReader.update! unless ActivityStreamLog.where(status: "Running").exists?
  end
end
