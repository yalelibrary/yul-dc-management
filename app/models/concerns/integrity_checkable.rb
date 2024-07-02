# frozen_string_literal: true

module IntegrityCheckable
  extend ActiveSupport::Concern

  def integrity_check
    # need to update so it only grabs children that do not belong to preservica parents
    # non_preservica_parents = ParentObject.where.not(digital_object_source: 'Preservica')
    # child_objects_pool = non_preservica_parents.map(&:child_objects)
    # # non_preservica_parents.each do |po|
    # #   child_objects_pool << po.child_objects
    # # end
    # child_object_sample = child_objects_pool.where(oid: child_objects_pool.ids.sample(2000)) 
    child_object_sample = ChildObject.where(oid: ChildObject.ids.sample(2000)) 

    child_object_sample.each do |co|

      attach_item(co.parent_object)
      attach_item(co)

      if co.access_master_exists? 
        if co.access_master_checksum_matches?
          co.processing_event("Child Object: #{co.oid} checksum matches and file exists.", 'review-complete')
          co.parent_object.processing_event("Integrity check complete for Child Object: #{co.oid}", 'complete')
        else
          co.processing_event("Child Object: #{co.oid} file exists but the file's checksum [#{co.access_master_checksum}] does not match what is saved on the child object [#{co.checksum}].", 'review-complete')
          co.parent_object.processing_event("Integrity check complete for Child Object: #{co.oid}", 'complete')
        end
      else
        co.processing_event("Child Object: #{co.oid} file not found at #{co.access_master_path} on #{ENV['ACCESS_MASTER_MOUNT']}.  Checksum could not be compared for the child object.", 'review-complete')
        co.parent_object.processing_event("Integrity check complete for Child Object: #{co.oid}", 'complete')
      end
    end

    batch_processing_event("Integrity Check complete. #{child_object_sample.count} Child Object records reviewed.", "Complete")
  end
end
