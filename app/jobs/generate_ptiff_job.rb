# frozen_string_literal: true

class GeneratePtiffJob < ApplicationJob
  queue_as :default

  def perform(oid)
    PyramidalTiffFactory.generate_ptiff_from(oid)
  end
end
