class AddSensitiveMaterialsToParentObject < ActiveRecord::Migration[7.0]
  def change
    add_column :parent_objects, :sensitive_materials, :string
  end
end
