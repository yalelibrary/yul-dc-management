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
      parent_object = updatable_parent_object(oid, index)
      next unless parent_object
      metadata_source = row['source'].presence || parent_object.authoritative_metadata_source.metadata_cloud_name

      processed_fields = validate_field(parent_object, row)
      next unless validate_metadata_source(metadata_source, index)
      setup_for_background_jobs(parent_object, metadata_source)
      parent_object.update(processed_fields)
      trigger_setup_metadata(parent_object)

      processing_event_for_parent(parent_object)
    end
  end

  def validate_field(parent_object, row)
    fields = ['aspace_uri', 'barcode', 'bib', 'digitization_note', 'holding', 'item', 'project_identifier', 'rights_statement']
    validation_fields = { "display_layout" => 'viewing_hints', "extent_of_digitization" => 'extent_of_digitizations', "viewing_direction" => 'viewing_directions', "visibility" => 'visibilities' }

    processed_fields = {}
    fields.each do |f|
      processed_fields[f.to_sym] = valid_regular_fields(row, f, parent_object)
    end
    validation_fields.each do |k, v|
      processed_fields[k.to_sym] = valid_controlled_vocab_fields(row, k, v, parent_object)
    end

    processed_fields
  end

  def processing_event_for_parent(parent_object)
    parent_object.current_batch_process = self
    parent_object.current_batch_connection = batch_connections.find_or_create_by(connectable: parent_object)
    parent_object.current_batch_connection.save!
    parent_object.processing_event("Parent #{parent_object.oid} has been updated", 'update-complete')
  end

  def remote_po_path(oid, metadata_source)
    "#{metadata_source}/#{oid}.json"
  end

  def valid_regular_fields(row, field_value, parent_object)
    if row[field_value].present? && row[field_value] != parent_object.send(field_value)
      row[field_value]
    else
      parent_object.send(field_value)
    end
  end

  def valid_controlled_vocab_fields(row, column_name, vocab, parent_object)
    if row[column_name].present? && row[column_name] != parent_object.send(column_name) && (ParentObject.send(vocab).include? row[column_name])
      row[column_name]
    elsif row[column_name].present? && row[column_name] != parent_object.send(column_name) && !(ParentObject.send(vocab).include? row[column_name])
      process_invalid_vocab_event(column_name, row[column_name], parent_object.oid)
      parent_object.send(column_name)
    else
      parent_object.send(column_name)
    end
  end

  # rubocop:disable Metrics/LineLength
  def process_invalid_vocab_event(column_name, row_value, oid)
    case column_name
    when 'display_layout'
      batch_processing_event("Parent #{oid} did not update value for Viewing Hint. Value: #{row_value} is invalid. For field Display Layout / Viewing Hint please use: individuals, paged, continuous, or leave column empty", 'Invalid Vocabulary')
    when 'extent_of_digitization'
      batch_processing_event("Parent #{oid} did not update value for Extent of Digitization. Value: #{row_value} is invalid. For field Extent of Digitization please use: Completely digitizied, Partially digitizied, or leave column empty", 'Invalid Vocabulary')
    when 'viewing_direction'
      batch_processing_event("Parent #{oid} did not update value for Viewing Directions. Value: #{row_value} is invalid. For field Viewing Direction please use: left-to-right, right-to-left, top-to-bottom, bottom-to-top, or leave column empty", 'Invalid Vocabulary')
    when 'visibility'
      batch_processing_event("Parent #{oid} did not update value for Visibility. Value: #{row_value} is invalid. For field Visibility please use: Private, Public, or Yale Community Only", 'Invalid Vocabulary')
    end
  end
  # rubocop:enable Metrics/LineLength

  def trigger_setup_metadata(parent_object)
    parent_object.current_batch_process = self
    parent_object.current_batch_connection = batch_connections.find_or_create_by(connectable: parent_object)
    parent_object.current_batch_connection.save!
    parent_object.save!
    SetupMetadataJob.perform_later(parent_object, self, parent_object.current_batch_connection)
  end
end
