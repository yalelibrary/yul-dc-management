# frozen_string_literal: true

class GeneratePdfJob < ApplicationJob
  queue_as :pdf

  def default_priority
    10
  end

  # rubocop:disable Metrics/MethodLength
  def perform(parent_object, current_batch_process = parent_object.current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    return unless parent_object.should_create_manifest_and_pdf?
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    parent_object.generate_pdf
    parent_object.processing_event("PDF has been generated", "pdf-generated")
  rescue RuntimeError => e
    if e.message.include?("Can not read scanlines from a tiled image")
      parent_object.processing_event("Unable to generate PDF: source image is in tiled format and cannot be processed.", "pdf-generation-failed")
      current_batch_process&.batch_processing_event("Unable to generate PDF: source image is in tiled format and cannot be processed.", "pdf-generation-failed")
    elsif e.message.include?("Invalid tile byte count")
      parent_object.processing_event("Unable to generate PDF: source image has invalid tile byte count and cannot be processed. Please regenerate the PTIFF.", "pdf-generation-failed")
      current_batch_process&.batch_processing_event("Unable to generate PDF for parent #{parent_object.oid}: source image has invalid tile byte count. Please regenerate the PTIFF.", "failed")
    else
      parent_object.processing_event("Unable to generate PDF, #{e.message}", "failed")
    end
    raise
  rescue => e
    parent_object.processing_event("Unable to generate PDF, #{e.message}", "failed")
    raise
  end
end
# rubocop:enable Metrics/MethodLength
