# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module RecreateChildPtiff
  extend ActiveSupport::Concern

  # RECREATE CHILD OID PTIFFS: -------------------------------------------------------------------- #

  # RECREATES CHILD OID PTIFFS FROM INGESTED CSV
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def recreate_child_oid_ptiffs(start_index = 0)
    parents = Set[]
    self.admin_set = ''
    sets = admin_set
    oids.each_with_index do |oid, index|
      child_object = ChildObject.find_by_oid(oid.to_i)
      unless child_object
        batch_processing_event("Skipping row [#{index + 2}] with unknown Child: #{oid}", 'Skipped Row')
        next
      end
      next unless child_object

      add_admin_set_to_bp(sets, child_object)
      save!

      configure_parent_object(child_object, parents)
      attach_item(child_object)
      next unless user_update_child_permission(child_object, child_object.parent_object)
      path = Pathname.new(child_object.access_master_path)
      file_size = File.exist?(path) ? File.size(path) : 0
      GeneratePtiffJob.set(queue: :large_ptiff).perform_later(child_object, self) if file_size > SetupMetadataJob::FIVE_HUNDRED_MB
      GeneratePtiffJob.perform_later(child_object, self) if file_size <= SetupMetadataJob::FIVE_HUNDRED_MB
      attach_item(child_object)
      child_object.processing_event("Ptiff Queued", "ptiff-queued")
      if index + 1 - start_index > 50
        return index + 1
      end
    end
    return -1
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity

  # CHECKS TO SEE IF USER HAS THE ABILITY TO UPDATE CHILD OBJECTS:
  def user_update_child_permission(child_object, parent_object)
    user = self.user
    unless current_ability.can? :update, child_object
      batch_processing_event("#{user.uid} does not have permission to update Child: #{child_object.oid} on Parent: #{child_object.parent_object.oid}", 'Permission Denied')
      child_object.processing_event("#{user.uid} does not have permission to update Child: #{child_object.oid}", 'Permission Denied')
      parent_object.processing_event("#{user.uid} does not have permission to update Child: #{child_object.oid}", 'Permission Denied')
      return false
    end

    true
  end

  # CONNECTS CHILD OIDS BATCH PROCESS TO PARENT OBJECT
  def configure_parent_object(child_object, parents)
    parent_object = child_object.parent_object
    unless parents.include? parent_object.oid
      attach_item(parent_object)
      parent_object.processing_event("Connection to batch created", "parent-connection-created")
      parents.add parent_object.oid
    end

    parents
  end
end
