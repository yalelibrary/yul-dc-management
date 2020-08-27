# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :default

  def perform(parent_object)
    parent_object.default_fetch
    parent_object.create_child_records
    parent_object.save!
    parent_object.child_objects.each do |c|
      GeneratePtiffJob.perform_later(c.child_oid)
    end
  end
end
