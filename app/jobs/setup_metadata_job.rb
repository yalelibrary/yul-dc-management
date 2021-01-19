# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :metadata

  def perform(parent_object, current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    parent_object.generate_manifest = true
    mets_images_present = check_mets_images(parent_object)
    return unless mets_images_present
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

  def check_mets_images(parent_object)
    if parent_object&.from_mets
      images_present = parent_object.current_batch_process&.mets_doc&.all_images_present?
      if images_present
        parent_object.processing_event("All mets images are available on mounted directory", "mets-present", parent_object.current_batch_process, parent_object.current_batch_connection)
      else
        parent_object.processing_event("Could not find all mets images on mounted directory", "failed", parent_object.current_batch_process, parent_object.current_batch_connection)
      end
      images_present
    else
      true
    end
  end
end
