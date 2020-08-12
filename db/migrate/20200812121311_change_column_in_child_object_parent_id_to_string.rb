class ChangeColumnInChildObjectParentIdToString < ActiveRecord::Migration[6.0]
  def change
    change_column :child_objects, :parent_object_id, :string
  end
end
