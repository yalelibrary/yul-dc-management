class AddDefaultVisibilitytoParentObjects < ActiveRecord::Migration[6.0]
  def change
    change_column :parent_objects, :visibility, :string, default: "Private"
  end
end
