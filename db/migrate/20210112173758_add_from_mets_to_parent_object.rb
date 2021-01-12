class AddFromMetsToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :from_mets, :boolean, default: false
  end
end
