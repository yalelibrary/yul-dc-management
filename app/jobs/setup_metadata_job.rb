# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :metadata

  def perform(parent_object, current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    parent_object.generate_manifest = true
    mets_images_present = check_mets_images(parent_object, current_batch_process, current_batch_connection)
    return unless mets_images_present
    # Do not continue running the background jobs if the metadata has not been successfully fetched
    return unless parent_object.default_fetch(current_batch_process, current_batch_connection)
    parent_object.create_child_records if parent_object.from_upstream_for_the_first_time?
    parent_object.save!
    parent_object.processing_event("Child object records have been created", "child-records-created")
    parent_object.child_objects.each do |child|
      parent_object.current_batch_process&.setup_for_background_jobs(child, nil)
      GeneratePtiffJob.perform_later(child, current_batch_process)
      child.processing_event("Ptiff Queued", "ptiff-queued")
    end
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
end
