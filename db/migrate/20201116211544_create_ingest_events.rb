class CreateIngestEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :ingest_events do |t|
      t.string :reason
      t.string :status
      t.references :batch_process, null: false, foreign_key: true
      t.references :batch_connection, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
