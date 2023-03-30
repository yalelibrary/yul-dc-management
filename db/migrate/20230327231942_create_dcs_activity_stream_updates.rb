class CreateDcsActivityStreamUpdates < ActiveRecord::Migration[6.1]
  def change
    create_table :dcs_activity_stream_updates do |t|
      t.bigint :oid
      t.string :md5_metadata_hash

      t.timestamps
    end
  end
end
