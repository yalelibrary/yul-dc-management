# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :metadata

  def perform(parent_object, current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    parent_object.generate_manifest = true
    if parent_object.from_mets
      # Check for images from background job, since only background workers can see mounted file system
      parent_object.processing_event("Could not find all images from METs document", "failed", current_batch_process, current_batch_connection) unless parent_object.current_batch_process.mets_doc.all_images_present?
    end
    # Do not continue running the background jobs if the metadata has not been successfully fetched
    return unless parent_object.default_fetch(current_batch_process, current_batch_connection)
    parent_object.create_child_records
    parent_object.save!
    parent_object.processing_event("Child object records have been created", "child-records-created", current_batch_process, current_batch_connection)
    parent_object.child_objects.each do |child|
      GeneratePtiffJob.perform_later(child, current_batch_process, current_batch_connection)
      child.processing_event("Ptiff Queued", "ptiff-queued", current_batch_process, current_batch_connection)
    end
  rescue => e
    parent_object.processing_event("Setup job failed to save: #{e.message}", "failed", current_batch_process, current_batch_connection)
    raise # this reraises the error after we document it
  end
end
