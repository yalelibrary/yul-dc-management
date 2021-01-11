class AddMetsAccessMasterPathToChildObject < ActiveRecord::Migration[6.0]
  def change
    add_column :child_objects, :mets_access_master_path, :string
  end
end
