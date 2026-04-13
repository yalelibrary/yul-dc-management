# frozen_string_literal: true

class CreatePreservicaChildrenJob < ApplicationJob
  FIVE_HUNDRED_MB = 524_288_000
  queue_as :default

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def perform(parent_object, current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    parent_object.create_child_records
    parent_object.save!
    parent_object.reload
    parent_object.gather_technical_image_metadata
    parent_object.processing_event("Child object records have been created", "child-records-created")
    ptiff_jobs_queued = false
    parent_object.child_objects.each do |child|
      current_batch_process&.setup_for_background_jobs(child, nil)
      if child.pyramidal_tiff.height_and_width? && !child.pyramidal_tiff.force_update && S3Service.s3_exists?(child.remote_ptiff_path)
        child.processing_event("PTIFF exists on S3, not converting: #{child.oid}", 'ptiff-ready-skipped')
      else
        path = Pathname.new(child.access_primary_path)
        file_size = File.exist?(path) ? File.size(path) : 0
        GeneratePtiffJob.set(queue: :large_ptiff).perform_later(child, current_batch_process) if file_size > FIVE_HUNDRED_MB
        GeneratePtiffJob.perform_later(child, current_batch_process) if file_size <= FIVE_HUNDRED_MB
        child.processing_event("Ptiff Queued", "ptiff-queued")
        ptiff_jobs_queued = true
      end
    end
    unless ptiff_jobs_queued
      GenerateManifestJob.perform_later(parent_object, current_batch_process, current_batch_connection) if parent_object.needs_a_manifest?
    end
  rescue => e
    parent_object.processing_event("Preservica child creation failed: #{e.message}", "failed")
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
end
