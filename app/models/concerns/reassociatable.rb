# frozen_string_literal: true

module Reassociatable
  extend ActiveSupport::Concern
  include Updatable

  def reassociate_child_oids
    return unless batch_action == "reassociate child oids"
    parents_needing_update = update_child_objects
    update_related_parent_objects(parents_needing_update)
  end

  def update_child_objects
    return unless batch_action == "reassociate child oids"
    parents_needing_update = []
    parsed_csv.each_with_index do |row, index|
      co = load_child(index, row["child_oid"].to_i)
      po = load_parent(index, row["parent_oid"].to_i)
      next unless co.present? && po.present?

      attach_item(po)
      attach_item(co)
      next unless user_update_child_permission(co, po)

      parents_needing_update << co.parent_object.oid
      parents_needing_update << row["parent_oid"].to_i
      order = extract_order(index, row)
      next if order == :invalid_order
      reassociate_child(co, po, row)
    end
    parents_needing_update
  end

  def reassociate_child(co, po, row)
    # byebug
    co.parent_object = po
    co.order = row["order"].present? ? row["order"] : co.order
    co.label = row["label"].present? ? row["label"] : co.label
    co.caption = row["caption"].present? ? row["caption"] : co.caption
    co.viewing_hint = row["viewing_hint"].present? ? row["viewing_hint"] : co.viewing_hint
    co.parent_object.authoritative_json["title"] = row["parent_title"].present? ? row["parent_title"] : co.parent_object.authoritative_json["title"]
    co.parent_object.call_number = row["call_number"].present? ? row["call_number"] : co.parent_object.call_number
    processing_event_for_child(co)
    co.save!
  end

  def processing_event_for_child(co)
    co.current_batch_process = self
    co.current_batch_connection = batch_connections.find_or_create_by(connectable: co)
    co.current_batch_connection.save!
    co.processing_event("Child has parent #{co.parent_object.oid}", 'reassociate-complete')
  end

  def extract_order(index, row)
    unless row["order"]&.to_i&.positive? || row["order"] == '0'
      batch_processing_event("Skipping row [#{index + 2}] with invalid order [#{row['order']}] (Parent: #{row['parent_oid']}, Child: #{row['child_oid']})", 'Skipped Row')
      return :invalid_order
    end
    row["order"].to_i
  end

  def load_child(index, oid)
    co = ChildObject.find_by_oid(oid)
    batch_processing_event("Skipping row [#{index + 2}] with Child Missing #{oid}", 'Skipped Row') unless co
    co
  end

  def load_parent(index, oid)
    po = ParentObject.find_by_oid(oid)
    batch_processing_event("Skipping row [#{index + 2}] with Parent Missing #{oid}", 'Skipped Row') unless po
    po
  end

  def update_related_parent_objects(parents_needing_update)
    return unless batch_action == "reassociate child oids"
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
