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
      extent_from_ladybird = parent.ladybird_json&.[]("extentOfDigitization")&.first
      # There is a typo in some of the data that we should not perpetuate
      parent.extent_of_digitization = if extent_from_ladybird == "Complete work digitzed."
                                        "Complete work digitized."
                                      else
                                        extent_from_ladybird
                                      end
      parent.save!
    end
  end
end
