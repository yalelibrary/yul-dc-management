class AddManifestFlagToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :generate_manifest, :boolean, default: false
  end
end
