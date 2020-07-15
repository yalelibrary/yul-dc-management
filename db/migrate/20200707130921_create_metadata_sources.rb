class CreateMetadataSources < ActiveRecord::Migration[6.0]
  def change
    create_table :metadata_sources do |t|
      t.string :metadata_cloud_name
      t.string :display_name
      t.string :file_prefix

      t.timestamps
    end
  end
end
