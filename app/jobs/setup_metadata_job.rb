# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :metadata

  def perform(parent_object, current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    parent_object.generate_manifest = true
    mets_images_present = check_mets_images(parent_object, current_batch_process, current_batch_connection)
    unless mets_images_present
      parent_object.processing_event("SetupMetadataJob failed to find all images.", "failed")
      return
    end
    unless parent_object.default_fetch(current_batch_process, current_batch_connection)
      # Don't retry in this case. default_fetch() will throw an exception if it's a network error and trigger retry
      parent_object.processing_event("SetupMetadataJob failed to retrieve authoritative metadata. [#{parent_object.metadata_cloud_url}]", "failed")
      return
    end
    setup_child_object_jobs(parent_object, current_batch_process)
  rescue => e
    parent_object.processing_event("Setup job failed to save: #{e.message}", "failed")
    raise # this reraises the error after we document it
  end

  def check_mets_images(parent_object, current_batch_process, _current_batch_connection)
    if parent_object.from_mets
      current_batch_process.mets_doc.all_images_present?
    else
      true
    end
  end

  def setup_child_object_jobs(parent_object, current_batch_process)
    parent_object.create_child_records if parent_object.from_upstream_for_the_first_time?
    parent_object.save!
    parent_object.processing_event("Child object records have been created", "child-records-created")
    ptiff_jobs_queued = false
    parent_object.child_objects.each do |child|
      parent_object.current_batch_process&.setup_for_background_jobs(child, nil)
      if child.pyramidal_tiff.height_and_width? && child.pyramidal_tiff.file_on_s3
        child_object.processing_event("PTIFF exists on S3, not converting: #{child.oid}", 'ptiff-ready-skipped')
      else
        GeneratePtiffJob.perform_later(child, current_batch_process)
        child.processing_event("Ptiff Queued", "ptiff-queued")
        ptiff_jobs_queued = true
      end
    end
    GenerateManifestJob.perform_later(parent_object, parent_object.current_batch_process, parent_object.current_batch_connection) if parent_object.needs_a_manifest? && !ptiff_jobs_queued
  rescue => child_create_error
    parent_object.processing_event(child_create_error.message, "failed")
  end
end
