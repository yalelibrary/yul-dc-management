class AddVisibilityToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :visibility, :string
  end
end
