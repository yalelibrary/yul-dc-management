class AddChildObjectCountToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :child_object_count, :integer
  end
end
