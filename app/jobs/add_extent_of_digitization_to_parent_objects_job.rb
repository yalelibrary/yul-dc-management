# frozen_string_literal: true

# TODO: this is a onetime thing for a data migration
# it can be removed after 4/1/2021
class AddExtentOfDigitizationToParentObjectsJob < ApplicationJob
  queue_as :default

  def default_priority
    -100
  end

  def perform(*_args)
    ParentObject.where(extent_of_digitization: nil).find_each do |parent|
      parent.extent_of_digitization = parent.normalize_extent_of_digitization
      parent.save!
    end
  end
end
