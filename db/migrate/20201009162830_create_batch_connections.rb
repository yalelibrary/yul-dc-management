class CreateBatchConnections < ActiveRecord::Migration[6.0]
  def change
    create_table :batch_connections do |t|
      t.references :batch_process, null: false, foreign_key: true
      t.references :connection, polymorphic: true, null: false

      t.timestamps
    end
  end
end
