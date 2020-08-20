# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :default

  def perform(parent_object)
    parent_object.default_fetch
    parent_object.create_child_records
    parent_object.save!
  end
end
