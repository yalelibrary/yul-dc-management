# frozen_string_literal: true

class RefreshMetadataCloudCsvJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process)
    batch_process.refresh_metadata_cloud_csv
  end
end
