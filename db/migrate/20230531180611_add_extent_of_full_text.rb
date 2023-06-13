class AddExtentOfFullText < ActiveRecord::Migration[6.1]
  def change
    add_column :parent_objects, :extent_of_full_text, :text
    add_column :child_objects, :extent_of_full_text, :text
  end
end
