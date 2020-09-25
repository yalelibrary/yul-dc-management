# frozen_string_literal: true

class GeneratePtiffJob < ApplicationJob
  queue_as :default

  def perform(child_object)
    child_object.convert_to_ptiff!
    # Only generate manifest if all children are ready
    GenerateManifestJob.perform_later(child_object.parent_object) if child_object.parent_object.ready_for_manifest?
  end
end
