class RenameColumnChildObjectsChildOidToOid < ActiveRecord::Migration[6.0]
  def change
    rename_column :child_objects, :child_oid, :oid
  end
end
