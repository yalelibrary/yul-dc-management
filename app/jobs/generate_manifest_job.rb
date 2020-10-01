# frozen_string_literal: true

class GenerateManifestJob < ApplicationJob
  queue_as :default

  def default_priority
    -30
  end

  def perform(parent_object)
    # generate iiif manifest and save it to s3
    parent_object.iiif_presentation.save
    result = parent_object.solr_index
    parent_object.processing_failure("Solr index after manifest generation failed") unless result
  rescue => e
    parent_object.processing_failure("IIIF Manifest generation failed due to #{e.message}")
    raise # this reraises the error after we document it
  end
end
