class AddUserRefToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_reference :parent_objects, :authoritative_metadata_source, null: false, default: 1
    add_column :parent_objects, :ladybird_json, :jsonb
    add_column :parent_objects, :voyager_json, :jsonb
    add_column :parent_objects, :aspace_json, :jsonb
  end
end
