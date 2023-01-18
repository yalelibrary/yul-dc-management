
class UpdateManifestsJob < ApplicationJob
  queue_as :metadata

  def self.job_limit
    5000
  end

  def perform(start_position = 0, admin_set_id, batch_process)
    visibilities = ["Public", "Yale Community Only"]
    parent_objects = ParentObject.where(admin_set_id: admin_set_id, visibility: visibilities).where.not(child_object_count: 0).order(:oid).offset(start_position).limit(UpdateManifestsJob.job_limit)
    last_job = parent_objects.count < UpdateManifestsJob.job_limit
    return unless parent_objects.count.positive? # stop if nothing is found
    parent_objects.each do |po|
      po.current_batch_connection = batch_process&.batch_connections&.find_or_create_by(connectable: po)
      GenerateManifestJob.perform_later(po, batch_process, po.current_batch_connection)
    end
    UpdateManifestsJob.perform_later(start_position + parent_objects.count, admin_set_id) unless last_job
  end
end
