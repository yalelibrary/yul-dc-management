# frozen_string_literal: true

class GeneratePtiffJob < ApplicationJob
  queue_as :default

  def perform(child_object)
    conversion_information = PyramidalTiffFactory.generate_ptiff_from(child_object)
    return unless conversion_information
    child_object.width = conversion_information[:width]
    child_object.height = conversion_information[:height]
    child_object.save
  end
end
