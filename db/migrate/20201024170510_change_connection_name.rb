class ChangeConnectionName < ActiveRecord::Migration[6.0]
  def change
    rename_column :batch_connections, :connection_type, :connectable_type
    rename_column :batch_connections, :connection_id, :connectable_id
  end
end
