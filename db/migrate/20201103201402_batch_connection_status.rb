class BatchConnectionStatus < ActiveRecord::Migration[6.0]
  def change
    add_column :batch_connections, :status, :string
  end
end
