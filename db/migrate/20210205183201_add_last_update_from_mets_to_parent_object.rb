class AddLastUpdateFromMetsToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :last_mets_update, :datetime
  end
end
