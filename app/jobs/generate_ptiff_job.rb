# frozen_string_literal: true

class GeneratePtiffJob < ApplicationJob
  queue_as :default

  def perform(child_object)
    child_object.convert_to_ptiff
  end
end
