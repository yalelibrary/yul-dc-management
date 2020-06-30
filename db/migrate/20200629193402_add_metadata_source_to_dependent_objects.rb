class AddMetadataSourceToDependentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :dependent_objects, :metadata_source, :string
  end
end
