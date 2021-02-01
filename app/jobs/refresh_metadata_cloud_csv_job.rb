# frozen_string_literal: true

# TODO: this is a onetime thing for a data migration
# it can be removed after 3/1/2021
class RefreshMetadataCloudCsvJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(batch_process)
    batch_process.refresh_metadata_cloud_csv
  end
end
