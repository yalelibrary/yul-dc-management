# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :metadata

  def perform(parent_object, current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    return if redirect(parent_object)
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

  # index and return true if parent is a redirect
  def redirect(parent_object)
    if parent_object.redirect_to.present?
      parent_object.solr_index
      true
    else
      false
    end
  end

  def check_mets_images(parent_object, current_batch_process, _current_batch_connection)
    if parent_object.from_mets
      current_batch_process.mets_doc.all_images_present?
    else
      true
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def setup_child_object_jobs(parent_object, current_batch_process)
    parent_object.create_child_records if parent_object.from_upstream_for_the_first_time?
    parent_object.save!
    parent_object.processing_event("Child object records have been created", "child-records-created")
    ptiff_jobs_queued = false
    parent_object.child_objects.each do |child|
      parent_object.current_batch_process&.setup_for_background_jobs(child, nil)
      if child.pyramidal_tiff.height_and_width? && S3Service.s3_exists?(child.remote_ptiff_path)
        child.processing_event("PTIFF exists on S3, not converting: #{child.oid}", 'ptiff-ready-skipped')
      else
        path = Pathname.new(child.access_master_path)
        file_size = File.exist?(path) ? File.size(path) : 0
        # 1073741824 is 1GB in bytes
        GeneratePtiffJob.set(queue: :large_ptiff).perform_later(child, current_batch_process) if file_size > 1_073_741_824
        GeneratePtiffJob.perform_later(child, current_batch_process) if file_size <= 1_073_741_824
        child.processing_event("Ptiff Queued", "ptiff-queued")
        ptiff_jobs_queued = true
      end
    end
    unless ptiff_jobs_queued
      GenerateManifestJob.perform_later(parent_object, parent_object.current_batch_process, parent_object.current_batch_connection) if parent_object.needs_a_manifest?
    end
  rescue => child_create_error
    parent_object.processing_event(child_create_error.message, "failed")
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
