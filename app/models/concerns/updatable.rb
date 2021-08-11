# frozen_string_literal: true

module Updatable
  extend ActiveSupport::Concern

  def updatable_parent_object(oid, index)
    parent_object = ParentObject.find_by(oid: oid)
    if parent_object.blank?
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid} because it was not found in local database", 'Skipped Row')
      return false
    elsif !current_ability.can?(:update, parent_object)
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid}, user does not have permission to update.", 'Permission Denied')
      return false
    else
      parent_object
    end
  end

  def update_parent_objects
    return unless batch_action == "update parent objects"
    parsed_csv.each_with_index do |row, index|
      oid = row['oid'] unless ['oid'].nil?
      metadata_source = row['source'] unless row['source'].nil?
      parent_object = updatable_parent_object(oid, index)
      next unless parent_object

      processed_fields = process_fields_for_update(parent_object, row)
      setup_for_background_jobs(parent_object, metadata_source)
      parent_object.update(processed_fields)

      # delete old object from s3
      # replace with new metadata
      
      parent_object.current_batch_process = self
      parent_object.current_batch_connection = batch_connections.find_or_create_by(connectable: parent_object)
      parent_object.current_batch_connection.save!
      parent_object.save!

      GenerateManifestJob.perform_later(parent_object, self, parent_object.current_batch_connection)
      processing_event_for_parent(parent_object)
    end
  end

  # rubocop:disable Style/MultilineTernaryOperator
  # rubocop:disable Style/TernaryParentheses
  def process_fields_for_update(parent_object, row)
    fields = ['aspace_uri', 'barcode', 'bib', 'digitization_note', 'holding', 'item', 'rights_statement']
    validation_fields = { "display_layout" => 'viewing_hints', "extent_of_digitization" => 'extent_of_digitizations', "viewing_direction" => 'viewing_directions', "visibility" => 'visibilities' }

    processed_fields = {}
    fields.each do |f|
      processed_fields[f.to_sym] = (
        row[f].present? &&
        row[f] != parent_object.send(f)
      ) ? row[f] : parent_object.send(f)
    end
    validation_fields.each do |k, v|
      processed_fields[k.to_sym] = (
        row[k].present? &&
        row[k] != parent_object.send(k) &&
        (ParentObject.send(v).include? row[k])
      ) ? row[k] : parent_object.send(k)
    end

    processed_fields
  end
  # rubocop:enable Style/MultilineTernaryOperator
  # rubocop:enable Style/TernaryParentheses

  def processing_event_for_parent(parent_object)
    parent_object.current_batch_process = self
    parent_object.current_batch_connection = batch_connections.find_or_create_by(connectable: parent_object)
    parent_object.current_batch_connection.save!
    parent_object.processing_event("Parent #{parent_object.oid} has been updated", 'update complete')
  end
end
