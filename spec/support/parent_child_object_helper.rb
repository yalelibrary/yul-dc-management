module ParentChildObjectHelper
  def recreate_children(parent_object)
    ChildObject.delete_by(parent_object_oid: parent_object.oid)
    parent_object.create_child_records
  end
end