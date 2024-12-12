# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :metadata
  FIVE_HUNDRED_MB = 524_288_000

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Layout/LineLength
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
      parent_object.processing_event("Metadata Cloud could not access this descriptive record. Please make sure you have entered the correct information and that the descriptive records are public and/or published. ------------ Message from System: SetupMetadataJob failed to retrieve authoritative metadata. [#{parent_object.metadata_cloud_url}]", "failed")
      return
    end

    # TODO: comment in second conditional once Open with Permission objects can go live in production
    if parent_object.visibility == 'Open with Permission' && parent_object.permission_set_id.nil? # || (parent_object.authoritative_json&.[]('itemPermission') == 'Open with Permission' && parent_object.permission_set_id.nil?)
      permission_set = OpenWithPermission::PermissionSet.find_by(key: parent_object.permission_set&.key)
      if permission_set.nil?
        parent_object.processing_event("SetupMetadataJob failed. Permission Set information missing or nonexistent from CSV.  To successfully ingest a Permission Set Key value must be present for any parent objects that have 'Open with Permission' visibility. Parent Object has defaulted to private and no child objects were created.  Please delete parent object and re-attempt ingest with Permission Set Key and Visibility values in CSV.", 'failed')
        return
      end
    end
    setup_child_object_jobs(parent_object, current_batch_process)
    index_private(parent_object)
  rescue => e
    parent_object.processing_event(
"Metadata Cloud could not access this descriptive record. Please make sure you have entered the correct information, you have included a record source (ils or aspace), and, for aspace records, that you have included the public Archives at Yale address for the record. ------------ Message from System: Setup job failed to save: #{e.message}", "failed"
)
    raise # this reraises the error after we document it
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Layout/LineLength

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

  # even if metadata is missing we want to index data to solr so the object can be removed from blacklight
  def index_private(parent_object)
    parent_object.solr_index if parent_object.visibility == "Private"
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
      if child.pyramidal_tiff.height_and_width? && !child.pyramidal_tiff.force_update && S3Service.s3_exists?(child.remote_ptiff_path)
        child.processing_event("PTIFF exists on S3, not converting: #{child.oid}", 'ptiff-ready-skipped')
      else
        path = Pathname.new(child.access_master_path)
        file_size = File.exist?(path) ? File.size(path) : 0
        GeneratePtiffJob.set(queue: :large_ptiff).perform_later(child, current_batch_process) if file_size > FIVE_HUNDRED_MB
        GeneratePtiffJob.perform_later(child, current_batch_process) if file_size <= FIVE_HUNDRED_MB
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
