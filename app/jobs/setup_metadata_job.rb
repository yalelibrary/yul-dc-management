# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :default

  def perform(parent_object, current_batch_process)
    parent_object.current_batch_process = current_batch_process
    parent_object.default_fetch
    parent_object.create_child_records
    parent_object.save!
    parent_object.processing_event("Child object records have been created", "child-records-created")
    parent_object.child_objects.each do |c|
      GeneratePtiffJob.perform_later(c, current_batch_process)
    end
  rescue => e
    parent_object.processing_event("Setup job failed to save: #{e.message}", "failed")
    raise # this reraises the error after we document it
  end
end
