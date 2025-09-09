# frozen_string_literal: true

# Sends metrics to AWS
class AwsMetrics
  METRIC_NAMESPACE = 'DCS'
  METRIC_NAME = 'ActiveJob'
  METRIC_DIMENSION_CLUSTER = 'Cluster'
  METRIC_DIMENSION_JOB = 'JobName'
  METRIC_DIMENSION_EVENT = 'JobEvent'
  METRIC_FEATURE_FLAG = '|AWS_METRICS|'
  # Class names of jobs allowed to generate metrics
  LOGGABLE_JOBS = %w[SolrIndexJob SyncFromPreservicaJob GeneratePdfJob GeneratePtiffJob GenerateManifestJob ActivityStreamJob ProblemReportJob SetupMetadataJob UpdateAllMetadataJob].freeze

  def initialize
    @cloudwatch_client = Aws::CloudWatch::Client.new
    @metrics_enabled = ENV['FEATURE_FLAGS']&.include? METRIC_FEATURE_FLAG
    @cluster_name = ENV['CLUSTER_NAME'] || "unknown"
  end

  # rubocop:disable Metrics/MethodLength
  def publish_active_job_metric_data(job_name, event_name)
    unless @metrics_enabled
      Rails.logger.debug "[AwsMetrics] Cloudwatch logging feature flag is not enabled."
      return
    end
    unless LOGGABLE_JOBS.include? job_name
      Rails.logger.debug "[AwsMetrics] #{job_name} not loggable to Cloudwatch"
      return
    end
    Rails.logger.debug "[AwsMetrics] #{Time.now.utc} #{job_name} #{event_name}"
    @cloudwatch_client.put_metric_data(
      namespace: METRIC_NAMESPACE,
      metric_data: [
        {
          metric_name: METRIC_NAME,
          dimensions: [
            {
              name: METRIC_DIMENSION_CLUSTER,
              value: @cluster_name
            },
            {
              name: METRIC_DIMENSION_JOB,
              value: job_name
            },
            {
              name: METRIC_DIMENSION_EVENT,
              value: event_name
            }
          ],
          value: 1,
          unit: 'Count'
        }
      ]
    )
  end
  # rubocop:enable Metrics/MethodLength
end
