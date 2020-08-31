# frozen_string_literal: true

class GeneratePtiffJob < ApplicationJob
  queue_as :default

  def perform(child_object)
    # PyramidalTiffFactory.generate_ptiff_from(child_object)
  end
end
