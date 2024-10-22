# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Updatable
  extend ActiveSupport::Concern

  BLANK_VALUE = "_blank_"

  def updatable_parent_object(oid, index)
    parent_object = ParentObject.find_by(oid: oid)
    if parent_object.blank?
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid} because it was not found in local database", 'Skipped Row')
      false
    elsif !current_ability.can?(:update, parent_object)
      batch_processing_event("Skipping row [#{index + 2}] with parent oid: #{oid}, user does not have permission to update.", 'Permission Denied')
      false
    else
      parent_object
    end
  end

  def updatable_child_object(oid, index)
    child_object = ChildObject.find_by(oid: oid)
    if child_object.blank?
      batch_processing_event("Skipping row [#{index + 2}] with child oid: #{oid} because it was not found in local database", 'Skipped Row')
      false
    elsif !current_ability.can?(:update, child_object)
      batch_processing_event("Skipping row [#{index + 2}] with child oid: #{oid}, user does not have permission to update.", 'Permission Denied')
      false
    else
      child_object
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def update_child_objects_caption
    return unless batch_action == "update child objects caption and label"
    self.admin_set = ''
    sets = admin_set
    po_arr = []
    parsed_csv.each_with_index do |row, index|
      oid = row['oid'] unless ['oid'].nil?
      child_object = updatable_child_object(oid, index)
      next unless child_object
      parent_object = child_object.parent_object
      po_arr << parent_object
      attach_item(parent_object)
      add_admin_set_to_bp(sets, parent_object)
      save!
      child_object.caption = row['caption'] unless row['caption'].nil?
      child_object.label = row['label'] unless row['label'].nil?
      processed_fields = validate_child_field(child_object, row)
      child_object.update!(processed_fields)
      processing_event_for_child(child_object)
    end
    unique_po = po_arr.uniq(&:oid)
    unique_po.each do |parent_object|
      trigger_setup_metadata(parent_object)
      processing_event_for_parent(parent_object)
    end
  end

  # rubocop:disable Metrics/BlockLength
  def update_parent_objects
    self.admin_set = ''
    sets = admin_set
    return unless batch_action == "update parent objects"
    parsed_csv.each_with_index do |row, index|
      oid = row['oid'] unless ['oid'].nil?
      redirect = row['redirect_to'] unless ['redirect_to'].nil?
      parent_object = updatable_parent_object(oid, index)
      next unless parent_object
      admin_set = editable_admin_set(row['admin_set'], oid, index) unless row['admin_set'].nil?
      next if admin_set == false
      add_admin_set_to_bp(sets, parent_object)
      save!
      next if redirect.present? && !validate_redirect(redirect)
      next unless check_for_children(redirect, parent_object)

      processed_fields = validate_field(parent_object, row)
      # move metadata_source here since row is updated in validate_field
      metadata_source = row['source'].presence || parent_object.authoritative_metadata_source.metadata_cloud_name
      next unless validate_metadata_source(metadata_source, index)
      setup_for_background_jobs(parent_object, metadata_source)
      parent_object.admin_set = admin_set unless admin_set.nil?

      if row['visibility'] == "Open with Permission" && row['permission_set_key'].blank?
        batch_processing_event("Skipping row [#{index + 2}]. Process failed. Permission Set missing from CSV.", 'Skipped Row')
        next
      elsif row['visibility'] == "Open with Permission" && row['permission_set_key'] != parent_object&.permission_set&.key
        permission_set = OpenWithPermission::PermissionSet.find_by(key: row['permission_set_key'])
        if permission_set.nil?
          batch_processing_event("Skipping row [#{index + 2}]. Process failed. Permission Set missing or nonexistent.", 'Skipped Row')
          next
        elsif user.has_role?(:administrator, permission_set) || user.has_role?(:sysadmin)
          if parent_object.permission_set && !(user.has_role?(:administrator, parent_object.permission_set) || user.has_role?(:sysadmin))
            batch_processing_event("Skipping row [#{index + 2}] because user does not have edit permissions for the currently assigned Permission Set", 'Permission Denied')
            next
          else
            parent_object.permission_set = permission_set
          end
        else
          batch_processing_event("Skipping row [#{index + 2}] because user does not have edit permissions for this Permission Set: #{permission_set.key}", 'Permission Denied')
          next
        end
      end

      parent_object.update!(processed_fields)
      trigger_setup_metadata(parent_object)
      sync_from_preservica if parent_object.digital_object_source == 'Preservica'

      processing_event_for_parent(parent_object)
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/BlockLength
  # rubocop:enable Metrics/MethodLength

  # CHECKS TO SEE IF USER HAS ABILITY TO EDIT AN ADMIN SET:
  def editable_admin_set(admin_set_key, oid, index)
    admin_sets_hash = {}
    admin_sets_hash[admin_set_key] ||= AdminSet.find_by(key: admin_set_key)
    admin_set = admin_sets_hash[admin_set_key]
    if admin_set.blank?
      batch_processing_event("The admin set code is missing or incorrect. Please ensure an admin_set value is in the correct spreadsheet column and that your 3 or 4 letter code is correct.",
'Skipped Row')
      false
    elsif !current_ability.can?(:add_member, admin_set)
      batch_processing_event("Skipping row [#{index + 2}] because #{user.uid} does not have permission to create or update parent: #{oid}", 'Permission Denied')
      false
    else
      admin_set
    end
  end

  def remove_child_blanks(row, child_object)
    blankable = %w[caption label]
    blanks = {}
    row.delete_if do |k, v|
      if v == BLANK_VALUE
        if blankable.include?(k)
          blanks[k.to_sym] = nil
        else
          processing_event_invalid_child_blank(child_object, k)
        end
        true
      else
        false
      end
    end
    [row, blanks]
  end

  def validate_child_field(child_object, row)
    fields = ['caption', 'label']
    row, blanks = remove_child_blanks(row, child_object)
    processed_fields = {}
    fields.each do |f|
      processed_fields[f.to_sym] = valid_regular_child_fields(row, f, child_object)
    end
    processed_fields.merge!(blanks)
    processed_fields
  end

  def remove_blanks(row, parent_object)
    blankable = %w[aspace_uri barcode bib digitization_note holding item project_identifier rights_statement redirect_to display_layout extent_of_digitization viewing_direction]
    blanks = {}
    row.delete_if do |k, v|
      if v == BLANK_VALUE
        if blankable.include?(k)
          blanks[k.to_sym] = nil
        else
          processing_event_invalid_blank(parent_object, k)
        end
        true
      else
        false
      end
    end
    [row, blanks]
  end

  def validate_field(parent_object, row)
    fields = ['aspace_uri', 'barcode', 'bib', 'digital_object_source', 'digitization_funding_source', 'digitization_note', 'holding', 'item',
              'preservica_representation_type', 'preservica_uri', 'project_identifier', 'rights_statement', 'redirect_to']
    validation_fields = { "display_layout" => 'viewing_hints', "extent_of_digitization" => 'extent_of_digitizations', "viewing_direction" => 'viewing_directions', "visibility" => 'visibilities' }
    row, blanks = remove_blanks(row, parent_object)
    processed_fields = {}
    fields.each do |f|
      processed_fields[f.to_sym] = valid_regular_fields(row, f, parent_object)
    end
    validation_fields.each do |k, v|
      processed_fields[k.to_sym] = valid_controlled_vocab_fields(row, k, v, parent_object)
    end
    processed_fields.merge!(blanks)
    processed_fields
  end

  def processing_event_for_parent(parent_object)
    parent_object.current_batch_process = self
    parent_object.current_batch_connection = batch_connections.find_or_create_by(connectable: parent_object)
    parent_object.current_batch_connection.save!
    parent_object.processing_event("Parent #{parent_object.oid} has been updated", 'update-complete')
  end

  def processing_event_for_child(child_object)
    child_object.current_batch_process = self
    child_object.current_batch_connection = batch_connections.find_or_create_by(connectable: child_object)
    child_object.current_batch_connection.save!
    child_object.processing_event("Child #{child_object.oid} has been updated", 'update-complete')
  end

  def processing_event_invalid_blank(parent_object, field)
    batch_processing_event("Parent #{parent_object.oid} did not update value for #{field} because it can not be blanked.", 'Invalid Blank')
  end

  def processing_event_invalid_child_blank(child_object, field)
    batch_processing_event("Child #{child_object.oid} did not update value for #{field} because it can not be blanked.", 'Invalid Blank')
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

  def valid_regular_child_fields(row, field_value, child_object)
    if row[field_value].present? && row[field_value] != child_object.send(field_value)
      row[field_value]
    else
      child_object.send(field_value)
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

  # rubocop:disable Layout/LineLength
  def process_invalid_vocab_event(column_name, row_value, oid)
    case column_name
    when 'display_layout'
      batch_processing_event("Parent #{oid} did not update value for Viewing Hint. Value: #{row_value} is invalid. For field Display Layout / Viewing Hint please use: individuals, paged, continuous, or leave column empty", 'Invalid Vocabulary')
    when 'extent_of_digitization'
      batch_processing_event("Parent #{oid} did not update value for Extent of Digitization. Value: #{row_value} is invalid. For field Extent of Digitization please use: Completely digitizied, Partially digitizied, or leave column empty", 'Invalid Vocabulary')
    when 'viewing_direction'
      batch_processing_event("Parent #{oid} did not update value for Viewing Directions. Value: #{row_value} is invalid. For field Viewing Direction please use: left-to-right, right-to-left, top-to-bottom, bottom-to-top, or leave column empty", 'Invalid Vocabulary')
    when 'visibility'
      batch_processing_event("Parent #{oid} did not update value for Visibility. Value: #{row_value} is invalid. For field Visibility please use: Private, Public, Open with Permission, or Yale Community Only", 'Invalid Vocabulary')
    end
  end
  # rubocop:enable Layout/LineLength

  def trigger_setup_metadata(parent_object)
    parent_object.current_batch_process = self
    parent_object.current_batch_connection = batch_connections.find_or_create_by(connectable: parent_object)
    parent_object.current_batch_connection.save!
    parent_object.save!
    SetupMetadataJob.perform_later(parent_object, self, parent_object.current_batch_connection)
  end

  def check_for_children(redirect, parent_object)
    if redirect.nil?
      true
    elsif redirect && parent_object.child_objects.count.zero?
      true
    else
      batch_processing_event("Skipping row with parent oid: #{parent_object.oid} Child objects are attached to parent object.  Parent must have no children to be redirected.", 'Skipped Row')
      false
    end
  end

  def validate_redirect(redirect)
    if /\A((http|https):\/\/)?(collections-test.|collections-uat.|collections.)?library.yale.edu\/catalog\//.match?(redirect)
      true
    else
      batch_processing_event("Skipping row with redirect to: #{redirect}. Redirect to must be in format https://collections.library.yale.edu/catalog/1234567.", 'Skipped Row')
      false
    end
  end

  # CHECKS THAT METADATA SOURCE IS VALID - USED BY UPDATE
  def validate_metadata_source(metadata_source, index)
    if MetadataSource.all_metadata_cloud_names.include?(metadata_source)
      true
    else
      batch_processing_event("Skipping row [#{index + 2}] with unknown metadata source: #{metadata_source}.  Accepted values are 'ladybird', 'aspace', 'sierra', or 'ils'.", 'Skipped Row')
      false
    end
  end
end
# rubocop:enable Metrics/ModuleLength
