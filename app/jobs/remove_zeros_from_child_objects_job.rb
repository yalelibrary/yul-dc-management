# frozen_string_literal: true

# TODO: this is a onetime thing for a data migration
# it can be removed after 12/1/2020
class RemoveZerosFromChildObjectsJob < ApplicationJob
  queue_as :zeros

  def perform(*_args)
    ChildObject.where("height < ? OR width < ?", 1, 1).find_each do |child|
      child.height = nil
      child.width = nil
      child.ptiff_conversion_at = nil
      child.parent_object.generate_manifest = true
      child.parent_object.solr_delete
      GeneratePtiffJob.perform_later(child)
    end
  end
end
