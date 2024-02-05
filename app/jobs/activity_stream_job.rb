# frozen_string_literal: true

class ActivityStreamJob < ApplicationJob
  # rubocop:disable Rails/SaveBang
  def perform
    ActivityStreamReader.update unless ActivityStreamLog.where(status: "Running").exists?
  end
  # rubocop:enable Rails/SaveBang
end
