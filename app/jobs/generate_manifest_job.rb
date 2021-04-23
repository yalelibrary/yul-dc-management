# frozen_string_literal: true

class GenerateManifestJob < ApplicationJob
  queue_as :manifest

  def default_priority
    -30
  end

  def perform(parent_object, current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    generate_manifest(parent_object)
    index_to_solr(parent_object)
    GeneratePdfJob.perform_later(parent_object, current_batch_process, current_batch_connection)
  end

  def generate_manifest(parent_object)
    # generate iiif manifest and save it to s3
    upload = parent_object.iiif_presentation.save
    if upload
      parent_object.processing_event("IIIF Manifest saved to S3", "manifest-saved")
      parent_object.generate_manifest = false
      # Once we have successfully created all the ptiffs & created the manifest,
      # we should no longer need access to the original Goobi package, and should create any further
      # artifacts from the more persistent data available through the MetadataCloud, database, and access masters
      parent_object.from_mets = false
      parent_object.save!
    else
      parent_object.processing_event("IIIF Manifest not saved to S3", "failed")
    end
  rescue => e
    parent_object.processing_event("IIIF Manifest generation failed due to #{e.message}", "failed")
    raise # this reraises the error after we document it
  end

  def index_to_solr(parent_object)
    result = parent_object.solr_index
    if (result&.[]("responseHeader")&.[]("status"))&.zero?
      parent_object.processing_event("Solr index updated", "solr-indexed")
    else
      parent_object.processing_event("Solr index after manifest generation failed", "failed")
    end
  rescue => e
    parent_object.processing_event("Solr indexing failed due to #{e.message}", "failed")
    raise # this reraises the error after we document it
  end
end
