class AddPreservicaRepresentationNameToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :preservica_representation_name, :string
  end
end
