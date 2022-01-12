# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Reassociatable
  extend ActiveSupport::Concern

  #xx parse csv
  # look at each row
  # check the parent destination of the children
  # track which parent objects (reassociated FROM: old po) that have children removed from them
  # check old parent object to see if any children remain
  # if a child remains, do nothing to old parent redirect_to and no message/error
  # if no children remain and all children go to the same parent, redirect the old parent to the new parent 
  
  # triggers the reassociate process
  def reassociate_child_oids
    return unless batch_action == "reassociate child oids"
    parents_needing_update = update_child_objects
    # childern_neededing_update = update_child_objects
    update_related_parent_objects(parents_needing_update)
  end

  # finds which parents are needed to update
  def update_child_objects
    return unless batch_action == "reassociate child oids"
    parents_needing_update = []
    children_needing_update = []

    parsed_csv.each_with_index do |row, index|
      co = load_child(index, row["child_oid"].to_i)
      po = load_parent(index, row["parent_oid"].to_i)
      
      next unless co.present? && po.present?

      attach_item(po)
      attach_item(co)

      next unless user_update_child_permission(co, po)

      parents_needing_update << co.parent_object.oid
      parents_needing_update << row["parent_oid"].to_i

      reassociate_child(co, po)
      values_to_update = check_headers(child_headers, row)
      update_child_values(values_to_update, co, row, index)
    end
    # childern_needing_update
    parents_needing_update
  end

  # verifies headers are included. child headers found in csv_exportable:90
  def check_headers(headers, row)
    possible_headers = headers
    values_to_update = []
    possible_headers.each do |h|
      values_to_update << h if row.headers.include?(h)
    end
    values_to_update
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  # updates values based on column values for child object
  def update_child_values(values_to_update, co, row, index)
    values_to_update.each do |h|
      if h == 'viewing_hint'
        co.viewing_hint = valid_view(row[h], co.oid)
        # should not update parent title or call number
      elsif values_to_update.include? h
        if h == 'label'
          co.label = row[h]
        elsif h == 'caption'
          co.caption = row[h]
        elsif h == 'order'
          co.order = extract_order(index, row)
        elsif h == 'child_oid' || h == 'parent_oid'
          next
        end
      else
        next
      end
      co.save
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength

  # assigns the child to the new parent
  def reassociate_child(co, po)
    co.parent_object = po
    processing_event_for_child(co)
    co.save!
  end

  # alerts user of batch event
  def processing_event_for_child(co)
    co.current_batch_process = self
    co.current_batch_connection = batch_connections.find_or_create_by(connectable: co)
    co.current_batch_connection.save!
    co.processing_event("Child has parent #{co.parent_object.oid}", 'reassociate-complete')
  end

  # checks the increment is correct and in order
  def extract_order(index, row)
    unless row["order"]&.to_i&.positive? || row["order"] == '0'
      batch_processing_event("Skipping row [#{index + 2}] with invalid order [#{row['order']}] (Parent: #{row['parent_oid']}, Child: #{row['child_oid']})", 'Skipped Row')
      return :invalid_order
    end
    row["order"].to_i
  end

  # finds child object and adds alert if child cannot be found
  def load_child(index, oid)
    co = ChildObject.find_by_oid(oid)
    batch_processing_event("Skipping row [#{index + 2}] with Child Missing #{oid}", 'Skipped Row') unless co
    co
  end

  # finds parent object and adds alert if parent cannot be found
  def load_parent(index, oid)
    po = ParentObject.find_by_oid(oid)
    batch_processing_event("Skipping row [#{index + 2}] with Parent Missing #{oid}", 'Skipped Row') unless po
    po
  end

  # rubocop:disable Metrics/LineLength
  # checks if viewing hint is valid
  def valid_view(viewing_hint, oid)
    if ChildObject.viewing_hints.include? viewing_hint
      viewing_hint
    else
      batch_processing_event("Child #{oid} did not update value for Viewing Hint. Value: #{viewing_hint} is invalid. For field Viewing Hint please use: non-paged, facing-pages, or leave column empty", 'Invalid Vocabulary')
      nil
    end
  end
  # rubocop:enable Metrics/LineLength

  # updates count of parent objects and regenerates manifest pdf and reindexes solr.
  def update_related_parent_objects(parents_needing_update)
    return unless batch_action == "reassociate child oids" || batch_action == "delete child objects"
    parents_needing_update.uniq.each do |oid|
      po = ParentObject.find(oid)
      # TODO: What do we want to happen if the parent object no longer has any associated child objects?
      po.child_object_count = po.child_objects.count
      # If the child objects have changed, we'll need to re-create the manifest and PDF objects
      # and re-index to Solr
      po.current_batch_process = self
      po.current_batch_connection = batch_connections.find_or_create_by(connectable: po)
      po.current_batch_connection.save!
      po.save!
      GenerateManifestJob.perform_later(po, self, po.current_batch_connection)
    end
  end
end
# rubocop:enable Metrics/ModuleLength
