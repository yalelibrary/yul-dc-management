# frozen_string_literal: true

class GenerateManifestJob < ApplicationJob
  queue_as :default

  def default_priority
    -30
  end

  def perform(parent_object, current_batch_process)
    parent_object.current_batch_process = current_batch_process
    # generate iiif manifest and save it to s3
    begin
      parent_object.iiif_presentation.save
    rescue => e
      parent_object.processing_event("IIIF Manifest generation failed due to #{e.message}", "failed")
      raise # this reraises the error after we document it
    end
    begin
      result = parent_object.solr_index
      parent_object.processing_event("Solr index after manifest generation failed", "failed") unless result
    rescue => e
      parent_object.processing_event("Solr indexing failed due to #{e.message}", "failed")
      raise # this reraises the error after we document it
    end
  end
end
