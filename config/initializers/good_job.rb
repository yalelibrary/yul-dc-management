# frozen_string_literal: true

Rails.application.configure do
  # Configure options individually...
  config.good_job.preserve_job_records = true
  config.good_job.retry_on_unhandled_error = false
  config.good_job.on_thread_error = ->(exception) { Raven.capture_exception(exception) }
  config.good_job.execution_mode = :external
  # config.good_job.queues = '*'
  config.good_job.shutdown_timeout = 60 # seconds
  config.good_job.poll_interval = 5
  config.good_job.enable_cron = true
  config.good_job.cron = {
    activity: {
      # 15 minutes after midnight every day
      cron: '15 0 * * *',
      class: 'ActivityStreamJob'
    },
    problem: {
      cron: '15 0 * * *',
      class: 'ProblemReportJob'
    },
    update_permission_requests: {
      cron: '15 0 * * *',
      class: 'UpdatePermissionRequestsJob'
    }
  }
end
