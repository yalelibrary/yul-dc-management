class AddDefaultValueToExtentOfFullText < ActiveRecord::Migration[6.1]
  def up
    change_column :parent_objects, :extent_of_full_text, :text, default: "None"
  end
  
  def down
    change_column :parent_objects, :extent_of_full_text, :text, default: nil
  end
end
