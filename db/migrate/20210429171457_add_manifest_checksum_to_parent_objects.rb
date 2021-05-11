class AddManifestChecksumToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :manifest_checksum, :string
  end
end
