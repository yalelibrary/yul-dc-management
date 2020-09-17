# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :default

  def perform(parent_object)
    parent_object.default_fetch
    parent_object.create_child_records
    parent_object.save!
    parent_object.child_objects.each do |c|
      GeneratePtiffJob.perform_later(c)
    end
  rescue => e
    parent_object.processing_failure("Setup job failed to save: #{e.message}")
    raise # this reraises the error after we document it
  end
end
