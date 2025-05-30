class ChangeMetsAccessMasterPath < ActiveRecord::Migration[7.0]
  def change
    rename_column :child_objects, :mets_access_master_path, :mets_access_primary_path
  end
end
