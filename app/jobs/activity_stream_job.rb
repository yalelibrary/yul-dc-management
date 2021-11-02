# frozen_string_literal: true

class ActivityStreamJob < ApplicationJob
  repeat 'every day at 1am'

  def perform
    ActivityStreamReader.update
  end
end
