# frozen_string_literal: true

module ParentChildObjectHelper
  def recreate_children(parent_object)
    parent_object.child_object_count ||= 0
    ladybird_json = {}
    ladybird_json["children"] = []

    ChildObject.where(parent_object_oid: parent_object.oid).each do |child|
      parent_object.child_objects.push(child) unless parent_object.child_objects.include?(child)
      ladybird_json["children"] << child
      parent_object.child_object_count += 1
    end
    parent_object.ladybird_json = ladybird_json if parent_object.ladybird_json.blank?

    ChildObject.delete_by(parent_object_oid: parent_object.oid)
    parent_object.create_child_records
    parent_object # return new parent if the parent and child aren't actually linked due to test shenanigans
  end
end
