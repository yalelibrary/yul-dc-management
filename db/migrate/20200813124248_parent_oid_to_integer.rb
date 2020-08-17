class ParentOidToInteger < ActiveRecord::Migration[6.0]
  def change
    change_column :parent_objects, :oid, 'bigint USING CAST(oid AS bigint)', primary_key: true
    remove_column :parent_objects, :id
  end
end
