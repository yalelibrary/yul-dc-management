class AddSierraMetadataSource < ActiveRecord::Migration[6.1]
  def change
    add_column :parent_objects, :sierra_json, :jsonb
    add_column :parent_objects, :last_sierra_update, :datetime
  end
end
