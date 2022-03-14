# frozen_string_literal: true

# Delayed::Worker.queue_attributes = {
#   default: { priority: 10 },
#   events: { priority: 0 },
#   import: { priority: 20}
# }
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_run_time = 2.hours
Delayed::Worker.default_queue_name = :default
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = Rails.logger
if ENV['RAILS_ENV'] = 'development'
  Delayed::Worker.max_attempts = 3
else
  Delayed::Worker.max_attempts = 15
end
