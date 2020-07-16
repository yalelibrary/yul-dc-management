class AddGoobiColumnsToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :reading_direction, :string, default: "ltr"
    add_column :parent_objects, :pagination, :string, default: "individuals"
  end
end
