# frozen_string_literal: true

class GeneratePtiffFromMetsJob < ApplicationJob
  queue_as :ptiff

  def default_priority
    10
  end

  def perform(child_object, current_batch_process, current_batch_connection = child_object.parent_object.current_batch_connection)
    child_object.parent_object.current_batch_process = current_batch_process
    child_object.parent_object.current_batch_connection = current_batch_connection
    child_object.parent_object.from_mets = true
    copy_step_result = child_object.copy_to_access_master_pairtree
    child_object.convert_to_ptiff! if copy_step_result == true
    # Only generate manifest if all children are ready
    GenerateManifestJob.perform_later(child_object.parent_object, current_batch_process, current_batch_connection) if child_object.parent_object.needs_a_manifest?
  end
end
