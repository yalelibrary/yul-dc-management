class AddAlmaMetadataSource < ActiveRecord::Migration[7.0]
  def change
    add_column :parent_objects, :alma_json, :jsonb
    add_column :parent_objects, :last_alma_update, :datetime
  end
end
