class AddMmsIdFields < ActiveRecord::Migration[7.0]
  def change
    add_column :parent_objects, :mms_id, :string
    add_column :parent_objects, :alma_holding, :string
    add_column :parent_objects, :alma_item, :string
    add_index :parent_objects, :mms_id, unique: true, where: "(mms_id IS NOT NULL) OR (mms_id != '')"
    add_index :parent_objects, :alma_holding
    add_index :parent_objects, :alma_item
  end
end
