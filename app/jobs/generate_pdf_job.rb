# frozen_string_literal: true

class GeneratePdfJob < ApplicationJob
  queue_as :pdf

  def default_priority
    50
  end

  def perform(parent_object, current_batch_process = parent_object.current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    parent_object.generate_pdf
  rescue => e
    parent_object.processing_event("Unable to generate PDF, #{e.message}", "failed")
    raise
  end
end
