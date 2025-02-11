# frozen_string_literal: true

module Deletable
  extend ActiveSupport::Concern

  # DELETE PARENT OBJECTS: ------------------------------------------------------------------------ #

  # DELETES PARENT OBJECTS FROM INGESTED CSV
  # rubocop:disable Metrics/MethodLength
  def delete_parent_objects(start_index = 0)
    self.admin_set = ''
    sets = admin_set
    parsed_csv.each_with_index do |row, index|
      next if start_index > index
      oid = row['oid']
      action = row['action']
      metadata_source = row['source']
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid}, action value for oid must be 'delete' to complete deletion.", 'Invalid Vocab') if action != "delete"
      next unless action == 'delete'
      parent_object = deletable_parent_object(oid, index)
      next unless parent_object
      add_admin_set_to_bp(sets, parent_object)
      save!
      setup_for_background_jobs(parent_object, metadata_source)
      parent_object.destroy!
      parent_object.processing_event("Parent #{parent_object.oid} has been deleted", 'deleted')
      return index + 1 if index + 1 - start_index > BatchProcess::BATCH_LIMIT
    end
    -1
  end
  # rubocop:enable Metrics/MethodLength

  # CHECKS TO SEE IF USER HAS ABILITY TO DELETE OBJECTS:
  def deletable_parent_object(oid, index)
    parent_object = ParentObject.find_by(oid: oid)
    if parent_object.blank?
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid} because it was not found in local database", 'Skipped Row')
      false
    elsif !current_ability.can?(:destroy, parent_object)
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid}, user does not have permission to delete.", 'Permission Denied')
      false
    else
      parent_object
    end
  end

  # DELETE CHILD OBJECTS: ------------------------------------------------------------------------ #

  # DELETES CHILD OBJECTS FROM INGESTED CSV
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def delete_child_objects
    parents_needing_update = []
    self.admin_set = ''
    sets = admin_set
    parsed_csv.each_with_index do |row, index|
      oid = row['oid']
      action = row['action']
      metadata_source = row['source']
      batch_processing_event("Skipping row [#{index + 2}] with child oid: #{oid}, action value for oid must be 'delete' to complete deletion.", 'Invalid Vocab') if action != "delete"
      next unless action == 'delete'
      child_object = deletable_child_object(oid, index)
      next unless child_object
      add_admin_set_to_bp(sets, child_object)
      save!
      parents_needing_update << child_object.parent_object.oid
      setup_for_background_jobs(child_object, metadata_source)
      child_object.destroy!
      child_object.parent_object.processing_event("child #{child_object.oid} has been deleted", 'deleted')
    end
    update_related_parent_objects(parents_needing_update, {})
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # CHECKS TO SEE IF USER HAS ABILITY TO DELETE OBJECTS:
  def deletable_child_object(oid, index)
    child_object = ChildObject.find_by(oid: oid)
    if child_object.blank?
      batch_processing_event("Skipping row [#{index + 2}] with child oid: #{oid} because it was not found in local database", 'Skipped Row')
      false
    elsif !current_ability.can?(:destroy, child_object)
      batch_processing_event("Skipping row [#{index + 2}] with child oid: #{oid}, user does not have permission to delete.", 'Permission Denied')
      false
    else
      child_object
    end
  end
end
