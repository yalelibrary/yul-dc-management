class RemoveMmsIdUniqueIndex < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        remove_index :parent_objects, :mms_id
        add_index :parent_objects, :mms_id
      end
    
      dir.down do
        remove_index :parent_objects, :mms_id
        add_index :parent_objects, :mms_id, unique: true
      end
    end
  end
end
