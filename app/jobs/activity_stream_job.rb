# frozen_string_literal: true

class ActivityStreamJob < ApplicationJob
  repeat 'every day at 2am'

  def perform
    ActivityStreamReader.update
  end
end
