class AddImageMetadataToChildObject < ActiveRecord::Migration[7.0]
  def change
    add_column :child_objects, :image_metadata, :jsonb
  end
end
