# frozen_string_literal: true

class ActivityStreamJob < ApplicationJob
  def default_priority
    40
  end

  # rubocop:disable Rails/SaveBang
  def perform
    ActivityStreamReader.update unless ActivityStreamLog.where(status: "Running").exists?
  end
  # rubocop:enable Rails/SaveBang
end
