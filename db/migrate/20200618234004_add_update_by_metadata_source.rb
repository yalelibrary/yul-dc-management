class AddUpdateByMetadataSource < ActiveRecord::Migration[6.0]
  def change
    change_table :parent_objects do |t|
      t.rename :last_mc_update, :last_ladybird_update
      t.rename :last_id_upate, :last_id_update
    end
    add_column :parent_objects, :last_voyager_update, :datetime
    add_column :parent_objects, :last_aspace_update, :datetime
  end
end
