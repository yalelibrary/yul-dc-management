# frozen_string_literal: true

class GeneratePtiffJob < ApplicationJob
  queue_as :ptiff

  def default_priority
    10
  end

  # def perform(child_object, current_batch_process = child, current_batch_connection = child_object.parent_object.current_batch_connection)
  def perform(child_object)
    # TODO: Uncomment the line below to re-implement Goobi ingest and copy to the access master pair-tree.
    # There is a test in  spec/models/batch_process_spec.rb that should fail, take out the "pending" and logger
    # mocks there to see if it passes
    # child_object.copy_to_access_master_pairtree if child_object.parent_object.from_mets
    child_object.convert_to_ptiff!(current_batch_process&.batch_action == 'recreate child oid ptiffs')
    # Only generate manifest if all children are ready
    GenerateManifestJob.perform_later(child_object.parent_object, parent_object.current_batch_process, parent_object.current_batch_connection) if child_object.parent_object.needs_a_manifest?
  end
end
