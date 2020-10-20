class RenameParentObjectReadingDirection < ActiveRecord::Migration[6.0]
  def change
    rename_column :parent_objects, :reading_direction, :viewing_direction
    rename_column :parent_objects, :pagination, :display_layout
    add_column :parent_objects, :use_ladybird, :boolean, default: false
  end
end
