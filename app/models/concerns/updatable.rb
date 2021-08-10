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
      
      aspace_uri = ( 
        row['aspace_uri'].present? && 
        row['aspace_uri'] != parent_object.aspace_uri 
      ) ? row['aspace_uri'] : parent_object.aspace_uri
      bib = ( 
        row['bib'].present? && 
        row['bib'] != parent_object.bib 
      ) ? row['bib'] : parent_object.bib
      barcode = ( 
        row['barcode'].present? && 
        row['barcode'] != parent_object.barcode 
      ) ? row['barcode'] : parent_object.barcode
      digitization_note = ( 
        row['digitization_note'].present? && 
        row['digitization_note'] != parent_object.digitization_note 
      ) ? row['digitization_note'] : parent_object.digitization_note
      display_layout = ( 
        row['display_layout'].present? && 
        row['display_layout'] != parent_object.display_layout && 
        (ParentObject.viewing_hints.include? row['display_layout']) 
      ) ? row['display_layout'] : parent_object.display_layout
      extent_of_digitization = ( 
        row['extent_of_digitization'].present? && 
        row['extent_of_digitization'] != parent_object.extent_of_digitization && 
        (ParentObject.extent_of_digitizations.include? row['extent_of_digitization']) 
      ) ? row['extent_of_digitization'] : parent_object.extent_of_digitization
      holding = ( 
        row['holding'].present? && 
        row['holding'] != parent_object.holding 
      ) ? row['holding'] : parent_object.holding
      item = ( 
        row['item'].present? && 
        row['item'] != parent_object.item 
      ) ? row['item'] : parent_object.item
      rights_statement = ( 
        row['rights_statement'].present? && 
        row['rights_statement'] != parent_object.rights_statement 
      ) ? row['rights_statement'] : parent_object.rights_statement
      viewing_direction = ( 
        row['viewing_direction'].present? && 
        row['viewing_direction'] != parent_object.viewing_direction && 
        (ParentObject.viewing_directions.include? row['viewing_direction']) 
      ) ? row['viewing_direction'] : parent_object.viewing_direction
      visibility = ( 
        row['visibility'].present? && 
        row['visibility'] != parent_object.visibility && 
        (ParentObject.visibilities.include? row['visibility']) 
      ) ? row['visibility'] : parent_object.visibility

      setup_for_background_jobs(parent_object, metadata_source)

      parent_object.update(
        aspace_uri: aspace_uri,
        barcode: barcode,
        bib: bib,
        digitization_note: digitization_note,
        display_layout: display_layout,
        extent_of_digitization: extent_of_digitization,
        holding: holding,
        item: item,
        rights_statement: rights_statement,
        viewing_direction: viewing_direction,
        visibility: visibility,
      )
    
      # delete old object from s3
      # replace with new metadata
      # GenerateManifestJob.perform_later(po, self, po.current_batch_connection)
      processing_event_for_parent(parent_object)
    end
  end

  def processing_event_for_parent(po)
    po.current_batch_process = self
    po.current_batch_connection = batch_connections.find_or_create_by(connectable: po)
    po.current_batch_connection.save!
    po.processing_event("Parent #{po.oid} has been updated", 'update complete')
  end
end
