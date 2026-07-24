class AddStructureFieldsToChildObjects < ActiveRecord::Migration[7.2]
  def change
    add_column :child_objects, :preservica_information_object_id, :string
    add_column :child_objects, :preservica_folder_label, :string
    add_column :child_objects, :preservica_folder_index, :integer
    add_column :child_objects, :preservica_content_object_index, :integer
  end
end
