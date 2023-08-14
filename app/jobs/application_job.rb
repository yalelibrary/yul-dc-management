# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # Override default_priority  to set the default priority for a job w/o sacrificing the ability
  # to set priority at run time via `Job.set(priority: 55).perform_later`
  def default_priority
    0
  end

  def priority
    @priority || default_priority
  end

  # limit to 3 attempts for local but 15 in production
  if ENV['RAILS_ENV'] == 'development'
    retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |_job, _exception|
      # Log error, do nothing, etc.
    end
  else
    retry_on StandardError, wait: :exponentially_longer, attempts: 15 do |_job, _exception|
      # Log error, do nothing, etc.
    end
  end
end
