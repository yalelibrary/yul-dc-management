# frozen_string_literal: true

class GenerateManifestJob < ApplicationJob
  queue_as :manifest

  def default_priority
    -30
  end

  def perform(parent_object, current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    return if parent_has_children_without_dimensions(parent_object)
    if parent_object.should_create_manifest_and_pdf?
      generate_manifest(parent_object)
      parent_object.save!
    end
    parent_object.solr_index_job
    GeneratePdfJob.perform_later(parent_object, current_batch_process, current_batch_connection) if parent_object.should_create_manifest_and_pdf?
  end

  def generate_manifest(parent_object)
    # generate iiif manifest and save it to s3
    upload = parent_object.iiif_presentation.save
    if upload
      parent_object.processing_event('IIIF Manifest saved to S3', 'manifest-saved')
      parent_object.generate_manifest = false
      # Once we have successfully created all the ptiffs & created the manifest,
      # we should no longer need access to the original Goobi package, and should create any further
      # artifacts from the more persistent data available through the MetadataCloud, database, and access masters
      parent_object.from_mets = false
      parent_object.save!
    else
      parent_object.processing_event('IIIF Manifest not saved to S3', 'failed')
    end
  rescue => e
    parent_object.processing_event("IIIF Manifest generation failed due to #{e.message}", 'failed')
    raise # this reraises the error after we document it
  end

  def parent_has_children_without_dimensions(parent_object)
    status = false
    parent_object.child_objects.each do |child_object|
      status = true if child_object.width.nil? || child_object.height.nil?
    end
    status
  end
end
