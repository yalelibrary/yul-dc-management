class AddPreservicaToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :preservica_uri, :string
    add_column :parent_objects, :digital_object_source, :string
  end
end
