# frozen_string_literal: true

module Reassociatable
  extend ActiveSupport::Concern

  def reassociate_child_oids
    return unless batch_action == "reassociate child oids"
    original_parent_oids = update_child_objects
    update_parent_objects(original_parent_oids)
  end

  def update_child_objects
    return unless batch_action == "reassociate child oids"
    original_parent_oids = []
    parsed_csv.each_with_index do |row|
      co = ChildObject.find(row["child_oid"].to_i)
      original_parent_oids << co.parent_object.oid
      po = ParentObject.find(row["parent_oid"].to_i)
      co.order = row["order"]
      co.label = row["label"]
      co.caption = row["caption"]
      co.parent_object = po
      co.save!
    end
    original_parent_oids
  end

  def update_parent_objects(original_parent_oids)
    return unless batch_action == "reassociate child oids"
    original_parent_oids.uniq.each do |oid|
      po = ParentObject.find(oid)
      # TODO: What do we want to happen if the parent object no longer has any associated child objects?
      po.child_object_count = po.child_objects.count
      # If the child objects have changed, we'll need to re-create the manifest and PDF objects
      # and re-index to Solr
      po.metadata_update = true
      po.save!
    end
  end
end
