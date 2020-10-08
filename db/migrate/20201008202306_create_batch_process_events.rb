class CreateBatchProcessEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :batch_process_events do |t|
      t.references :batch_process, null: false, foreign_key: true
      t.references :parent_object_oid, references: :parent_objects, null: false
      t.datetime :queued, precision: 6
      t.datetime :metadata_fetched, precision: 6
      t.datetime :child_records_created, precision: 6
      t.datetime :ptiff_jobs_created, precision: 6
      t.datetime :iiif_manifest_saved, precision: 6
      t.datetime :indexed_to_solr, precision: 6

      t.timestamps
    end
    rename_column :batch_process_events, :parent_object_oid_id, :parent_object_oid
    add_foreign_key :batch_process_events, :parent_objects, column: 'parent_object_oid', primary_key: 'oid'
  end
end
