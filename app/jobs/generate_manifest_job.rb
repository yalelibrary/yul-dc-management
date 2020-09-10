class GenerateManifestJob < ApplicationJob
  queue_as :default

  def perform(parent_object)
    # generate iiif manifest and save it to s3
    parent_object.iiif_presentation.save
  end
end
