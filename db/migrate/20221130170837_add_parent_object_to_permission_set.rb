class AddParentObjectToPermissionSet < ActiveRecord::Migration[6.0]
  def change
    add_reference :permission_sets, :parent_object
  end
end
