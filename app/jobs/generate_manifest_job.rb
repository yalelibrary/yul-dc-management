# frozen_string_literal: true

class GenerateManifestJob < ApplicationJob
  queue_as :default

  def perform(parent_object)
    # generate iiif manifest and save it to s3
    parent_object.iiif_presentation.save
    parent_object.solr_index
  end
end
