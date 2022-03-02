# frozen_string_literal: true

class GeneratePtiffJob < ApplicationJob
  queue_as :ptiff

  def default_priority
    10
  end

  def perform(child_object, batch_process)
    return if child_object.nil?
    child_object.current_batch_process = batch_process
    child_object.current_batch_connection = batch_process&.batch_connections&.find_or_create_by(connectable: child_object)
    parent_object = child_object.parent_object
    parent_object.current_batch_process = batch_process
    parent_object.current_batch_connection = batch_process&.batch_connections&.find_or_create_by(connectable: parent_object)

    # TODO: Uncomment the line below to re-implement Goobi ingest and copy to the access master pair-tree.
    # There is a test in spec/models/batch_process_spec.rb that should fail, take out the "pending" and logger
    # mocks there to see if it passes
    child_object.copy_to_access_master_pairtree if child_object.parent_object.from_mets || child_object.preservica_bitstream_uri
    is_recreate_job = child_object.current_batch_process&.batch_action == 'recreate child oid ptiffs'
    success = child_object.convert_to_ptiff!(is_recreate_job)
    raise "Unable to convert to PTIFF and save child object: #{child_object.oid}" unless success
    # Only generate manifest if all children are ready
    GenerateManifestJob.perform_later(parent_object, parent_object.current_batch_process, parent_object.current_batch_connection) if parent_object.needs_a_manifest?

    parent_object.processing_event('Ptiffs recreated', 'ptiffs-recreated') if is_recreate_job && batch_process.are_all_children_complete?(parent_object)
  end
end
