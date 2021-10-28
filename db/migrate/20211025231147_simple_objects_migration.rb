class SimpleObjectsMigration < ActiveRecord::Migration[6.0]
  def change
    add_column :child_objects, :original_oid, :integer
    add_index  :child_objects, :original_oid unless index_exists?(:child_objects, :original_oid)
    add_column :parent_objects, :parent_model, :string
    ParentObject.update_all("parent_model = 'complex'")
  end
end
