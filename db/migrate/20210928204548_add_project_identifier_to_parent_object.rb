class AddProjectIdentifierToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :project_identifier, :string
    add_index  :parent_objects, :project_identifier unless index_exists?(:parent_objects, :project_identifier)
  end
end
