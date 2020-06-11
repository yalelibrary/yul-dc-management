class AlterParentObjectOidUnique < ActiveRecord::Migration[6.0]
  def change
    add_index :parent_objects, :oid, unique: true
  end
end
