class AddAdminSetToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_reference :parent_objects, :admin_set, index: true
  end
end
