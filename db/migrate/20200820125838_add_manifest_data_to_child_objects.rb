class AddManifestDataToChildObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :child_objects, :label, :string
    add_column :child_objects, :checksum, :string
    add_column :child_objects, :viewing_hint, :string
  end
end
