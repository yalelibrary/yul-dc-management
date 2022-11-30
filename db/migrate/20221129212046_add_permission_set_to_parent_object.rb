class AddPermissionSetToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_reference :parent_objects, :permission_set, foreign_key: true
  end
end
