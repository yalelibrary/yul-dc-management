class RenamePreservicaRepresentation < ActiveRecord::Migration[6.0]
  def change
    rename_column :parent_objects, :preservica_representation_name, :preservica_representation_type
  end
end
