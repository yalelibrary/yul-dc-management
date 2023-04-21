# frozen_string_literal: true
require './app/lib/aws_metrics'

# Monitors ActiveJob events.  Events of interest:
# perform_start.active_job  ALWAYS FIRED
# enqueue_retry.active_job
# discard.active_job
# perform.active_job        ALWAYS FIRED
ActiveSupport::Notifications.subscribe /active_job/ do |event|
  logger = Rails.logger
  begin
    job_name = event.payload[:job].class.to_s
    executions = event.payload[:job].executions
    metrics = AwsMetrics.new
    case event.name
    when 'perform.active_job'
      if executions == 1
        metrics.publish_active_job_metric_data(job_name, 'perform')
      else
        metrics.publish_active_job_metric_data(job_name, 'perform-retry')
      end
    when 'discard.active_job'
      metrics.publish_active_job_metric_data(job_name, 'discard')
    when 'enqueue_retry.active_job'
      metrics.publish_active_job_metric_data(job_name, 'enqueue-retry')
    else
      logger.debug "Not publishing metrics for #{event.name}"
    end
  rescue StandardError => e
    logger.warn "Error handling event #{event&.name} #{event&.payload&.[](:job)&.class&.to_s} #{event} #{e}"
  end
end