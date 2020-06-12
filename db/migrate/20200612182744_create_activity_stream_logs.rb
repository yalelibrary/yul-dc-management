class CreateActivityStreamLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :activity_stream_logs do |t|
      t.datetime :run_time
      t.integer :object_count
      t.string :status

      t.timestamps
    end
  end
end
