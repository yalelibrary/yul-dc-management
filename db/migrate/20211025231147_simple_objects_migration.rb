class SimpleObjectsMigration < ActiveRecord::Migration[6.0]
  def change
    add_column :child_objects, :original_oid, :integer
    add_index  :child_objects, :original_oid unless index_exists?(:child_objects, :original_oid)
    add_column :parent_objects, :simple_object, :boolean
  end
end
