class ChangeColumnParentIdToString < ActiveRecord::Migration[6.0]
  def change
    change_column :dependent_objects, :parent_object_id, :string
  end
end
