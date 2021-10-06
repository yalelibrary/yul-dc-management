class AddChildObjectIndexes < ActiveRecord::Migration[6.0]
  def up
    add_index  :child_objects, :oid unless index_exists?(:child_objects, :oid)
    add_index  :child_objects, :parent_object_oid unless index_exists?(:child_objects, :parent_object_oid)
    add_index  :child_objects, :order unless index_exists?(:child_objects, :order)
    add_index  :child_objects, :label unless index_exists?(:child_objects, :label)
    add_index  :child_objects, :caption unless index_exists?(:child_objects, :caption)
  end

  def down
    remove_index :child_objects, :oid
    remove_index :child_objects, :parent_object_oid
    remove_index :child_objects, :order
    remove_index :child_objects, :label
    remove_index :child_objects, :caption
  end
end
