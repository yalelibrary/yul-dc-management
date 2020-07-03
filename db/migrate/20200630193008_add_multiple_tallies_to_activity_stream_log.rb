class AddMultipleTalliesToActivityStreamLog < ActiveRecord::Migration[6.0]
  def change
    rename_column :activity_stream_logs, :object_count, :activity_stream_items
    add_column :activity_stream_logs, :retrieved_records, :integer
  end
end
