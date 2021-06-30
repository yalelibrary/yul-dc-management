class AddContainerGroupingToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :container_grouping, :string
  end
end
