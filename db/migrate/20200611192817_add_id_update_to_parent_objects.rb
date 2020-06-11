class AddIdUpdateToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :last_id_upate, :datetime
  end
end
