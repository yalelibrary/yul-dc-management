class CreatePreservicaIngests < ActiveRecord::Migration[6.0]
  def change
    create_table :preservica_ingests do |t|
      t.datetime :ingest_time
      t.bigint :parent_oid
      t.bigint :child_oid
      t.string :preservica_id
      t.string :preservica_child_id
      t.bigint :batch_process_id

      t.timestamps
    end
  end
end
