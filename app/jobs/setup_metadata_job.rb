# frozen_string_literal: true

class SetupMetadataJob < ApplicationJob
  queue_as :metadata

  def perform(parent_object, current_batch_process, current_batch_connection = parent_object.current_batch_connection)
    # when creating parent objects, the following is failing with "undefined method `parent_object_id=' for #<SetupMetadataJob:0x0000563f388aad40>"
    puts ">>>SETUP METADATA JOB:: #{self.inspect}"
    # self.parent_object_oid = parent_object.oid

=begin
  #<SetupMetadataJob:0x0000560995a57f18
    @arguments= [
      #<ParentObject oid: 16854285,
        bib: nil,
        holding: nil,
        item: nil,
        barcode: nil,
        aspace_uri: nil,
        last_ladybird_update: nil,
        created_at: "2021-03-31 16:18:43",
        updated_at: "2021-03-31 16:18:43",
        last_id_update: nil,
        last_voyager_update: nil,
        last_aspace_update: nil,
        visibility: "Private",
        authoritative_metadata_source_id: 1,
        ladybird_json: nil,
        voyager_json: nil,
        aspace_json: nil,
        viewing_direction: nil,
        display_layout: nil,
        child_object_count: nil,
        generate_manifest: false,
        use_ladybird: true,
        representative_child_oid: nil,
        rights_statement: nil,
        from_mets: false,
        extent_of_digitization: nil,
        last_mets_update: nil,
        admin_set_id: 1,
      >,
      #<BatchProcess id: 3,
        csv: "oid,admin_set\n2034600,brbl\n2005512,brbl\n16414889,b...",
        mets_xml: nil,
        oid: nil,
        created_at: "2021-03-31 15:40:41",
        updated_at: "2021-03-31 15:40:41",
        user_id: 1,
        file_name: "short_fixture_ids.csv",
        batch_status: nil,
        batch_action: "create parent objects",
        output_csv: nil,
      >,
      #<BatchConnection id: 18,
        batch_process_id: 3,
        connectable_type: "ParentObject",
        connectable_id: 16854285,
        created_at: "2021-03-31 15:40:43",
        updated_at: "2021-03-31 15:40:43",
        status: "In progress - no failures",
      >
    ],
    @job_id="2b9d9bfd-39a4-456a-b026-7860b5552f2e",
    @queue_name="metadata",
    @priority=0,
    @executions=1,
    @exception_executions={},
    @provider_job_id=nil,
    @serialized_arguments=nil,
    @locale="en",
    @timezone="UTC",
    @enqueued_at="2021-03-31T15:40:43Z">
=end

    parent_object.delayed_jobs << self.job_id

    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    parent_object.generate_manifest = true
    mets_images_present = check_mets_images(parent_object, current_batch_process, current_batch_connection)
    unless mets_images_present
      parent_object.processing_event("SetupMetadataJob failed to find all images.", "failed")
      return
    end
    unless parent_object.default_fetch(current_batch_process, current_batch_connection)
      # Don't retry in this case. default_fetch() will throw an exception if it's a network error and trigger retry
      parent_object.processing_event("SetupMetadataJob failed to retrieve authoritative metadata. [#{parent_object.metadata_cloud_url}]", "failed")
      return
    end
    setup_child_object_jobs(parent_object, current_batch_process)
  rescue => e
    parent_object.processing_event("Setup job failed to save: #{e.message}", "failed")
    raise # this reraises the error after we document it
  end

  def check_mets_images(parent_object, current_batch_process, _current_batch_connection)
    if parent_object.from_mets
      current_batch_process.mets_doc.all_images_present?
    else
      true
    end
  end

  def setup_child_object_jobs(parent_object, current_batch_process)
    parent_object.create_child_records if parent_object.from_upstream_for_the_first_time?
    parent_object.save!
    parent_object.processing_event("Child object records have been created", "child-records-created")
    parent_object.child_objects.each do |child|
      parent_object.current_batch_process&.setup_for_background_jobs(child, nil)
      GeneratePtiffJob.perform_later(child, current_batch_process)
      child.processing_event("Ptiff Queued", "ptiff-queued")
    end
  rescue => child_create_error
    parent_object.processing_event(child_create_error.message, "failed")
  end
end
