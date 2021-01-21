# frozen_string_literal: true

class GenerateManifestJob < ApplicationJob
  queue_as :manifest

  def default_priority
    -30
  end

  def perform(parent_object, current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    generate_manifest(parent_object, current_batch_process, current_batch_connection)
    index_to_solr(parent_object, current_batch_process, current_batch_connection)
    GeneratePdfJob.perform_later(parent_object, current_batch_process, current_batch_connection)
  end

  def generate_manifest(parent_object, current_batch_process = parent_object.current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    # generate iiif manifest and save it to s3
    upload = parent_object.iiif_presentation.save
    if upload
      parent_object.processing_event("IIIF Manifest saved to S3", "manifest-saved", current_batch_process, current_batch_connection)
      parent_object.generate_manifest = false
      parent_object.save!
    else
      parent_object.processing_event("IIIF Manifest not saved to S3", "failed", current_batch_process, current_batch_connection)
    end
  rescue => e
    parent_object.processing_event("IIIF Manifest generation failed due to #{e.message}", "failed")
    raise # this reraises the error after we document it
  end

  def index_to_solr(parent_object, current_batch_process = parent_object.current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    result = parent_object.solr_index
    # if result.response[:status] == 200
    if result
      parent_object.processing_event("Solr index updated", "solr-indexed", current_batch_process, current_batch_connection)
    else
      parent_object.processing_event("Solr index after manifest generation failed", "failed", current_batch_process, current_batch_connection)
    end
  rescue => e
    parent_object.processing_event("Solr indexing failed due to #{e.message}", "failed", current_batch_process, current_batch_connection)
    raise # this reraises the error after we document it
  end
end
