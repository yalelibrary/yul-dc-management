# frozen_string_literal: true

# Delayed::Worker.queue_attributes = {
#   default: { priority: 10 },
#   events: { priority: 0 },
#   import: { priority: 20}
# }
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_run_time = 1.hour
Delayed::Worker.default_queue_name = :default
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = Rails.logger
