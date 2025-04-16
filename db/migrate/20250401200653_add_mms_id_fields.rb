class AddMmsIdFields < ActiveRecord::Migration[7.0]
  def change
    add_column :parent_objects, :mms_id, :string, unique: true
    add_column :parent_objects, :alma_holding, :string
    add_column :parent_objects, :alma_item, :string
  end
end
