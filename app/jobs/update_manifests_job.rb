# frozen_string_literal: true

class UpdateManifestsJob < ApplicationJob
  queue_as :default

  discard_on StandardError, Net::OpenTimeout

  def default_priority
    50
  end

  def perform(batch_process)
    batch_process.update_iiif_manifests
  end
end
