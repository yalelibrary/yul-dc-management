# frozen_string_literal: true

class RemoveFromMetadataCloudCsvJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process)
    batch_process.remove_from_metadata_cloud_csv
  end
end
