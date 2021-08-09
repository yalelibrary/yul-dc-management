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
      # admin_set = row['admin_set'] unless row['admin_set'].nil?
      visibility = row['visibility'] unless row['visibility'].nil?
      rights_statement = row['rights_statement'] unless row['rights_statement'].nil?
      extent_of_digitization = row['extent_of_digitization'] unless row['extent_of_digitization'].nil?
      digitization_note = row['digitization_note'] unless row['digitization_note'].nil?
      bib = row['bib'] unless row['bib'].nil?
      holding = row['holding'] unless row['holding'].nil?
      item = row['item'] unless row['item'].nil?
      barcode = row['barcode'] unless row['barcode'].nil?
      aspace_uri = row['aspace_uri'] unless row['aspace_uri'].nil?
      viewing_direction = row['viewing_direction'] unless row['viewing_direction'].nil?
      # viewing_hint doesn't appear to be an attribute of parent objects
      # viewing_hint = row['viewing_hint'] unless row['viewing_hint'].nil?

      parent_object = updatable_parent_object(oid, index)
      next unless parent_object
      setup_for_background_jobs(parent_object, metadata_source)
      # byebug
      # if value is diff than existing update but do not update if not different
      # if value is not valid then don't update
      # validated / controlled vocab - metadata source, visibility, extent of digitization, 
      # viewing direction, viewing hint

      parent_object.update(
        visibility: visibility.presence || parent_object.visibility,
        rights_statement: rights_statement.presence || parent_object.rights_statement,
        extent_of_digitization: extent_of_digitization.presence || parent_object.extent_of_digitization,
        digitization_note: digitization_note.presence || parent_object.digitization_note,
        bib: bib.presence || parent_object.bib,
        holding: holding.presence || parent_object.holding,
        item: item.presence || parent_object.item,
        barcode: barcode.presence || parent_object.barcode,
        aspace_uri: aspace_uri.presence || parent_object.aspace_uri,
        viewing_direction: viewing_direction.presence || parent_object.viewing_direction
      )
    end
  end

  # def reassociate_child_oids
  #   return unless batch_action == "reassociate child oids"
  #   parents_needing_update = update_child_objects
  #   update_parent_objects(parents_needing_update)
  # end

  # def update_child_objects
  #   return unless batch_action == "reassociate child oids"
  #   parents_needing_update = []
  #   parsed_csv.each_with_index do |row, index|
  #     co = load_child(index, row["child_oid"].to_i)
  #     po = load_parent(index, row["parent_oid"].to_i)
  #     next unless co.present? && po.present?

  #     attach_item(po)
  #     attach_item(co)
  #     next unless user_update_child_permission(co, po)

  #     parents_needing_update << co.parent_object.oid
  #     parents_needing_update << row["parent_oid"].to_i
  #     order = extract_order(index, row)
  #     next if order == :invalid_order
  #     reassociate_child(co, po, row)
  #   end
  #   parents_needing_update
  # end

  # def reassociate_child(co, po, row)
  #   co.order = row["order"] unless row["order"].nil?
  #   co.label = row["label"] unless row["label"].nil?
  #   co.caption = row["caption"] unless row["caption"].nil?
  #   co.parent_object = po
  #   processing_event_for_child(co)
  #   co.save!
  # end

  # def processing_event_for_child(co)
  #   co.current_batch_process = self
  #   co.current_batch_connection = batch_connections.find_or_create_by(connectable: co)
  #   co.current_batch_connection.save!
  #   co.processing_event("Child has parent #{co.parent_object.oid}", 'reassociate-complete')
  # end

  # def extract_order(index, row)
  #   unless row["order"]&.to_i&.positive? || row["order"] == '0'
  #     batch_processing_event("Skipping row [#{index + 2}] with invalid order [#{row['order']}] (Parent: #{row['parent_oid']}, Child: #{row['child_oid']})", 'Skipped Row')
  #     return :invalid_order
  #   end
  #   row["order"].to_i
  # end

  # def load_child(index, oid)
  #   co = ChildObject.find_by_oid(oid)
  #   batch_processing_event("Skipping row [#{index + 2}] with Child Missing #{oid}", 'Skipped Row') unless co
  #   co
  # end

  # def load_parent(index, oid)
  #   po = ParentObject.find_by_oid(oid)
  #   batch_processing_event("Skipping row [#{index + 2}] with Parent Missing #{oid}", 'Skipped Row') unless po
  #   po
  # end

  # def update_parent_objects(parents_needing_update)
  #   return unless batch_action == "reassociate child oids"
  #   parents_needing_update.uniq.each do |oid|
  #     po = ParentObject.find(oid)
  #     # TODO: What do we want to happen if the parent object no longer has any associated child objects?
  #     po.child_object_count = po.child_objects.count
  #     # If the child objects have changed, we'll need to re-create the manifest and PDF objects
  #     # and re-index to Solr
  #     po.current_batch_process = self
  #     po.current_batch_connection = batch_connections.find_or_create_by(connectable: po)
  #     po.current_batch_connection.save!
  #     po.save!
  #     GenerateManifestJob.perform_later(po, self, po.current_batch_connection)
  #   end
  # end
end
