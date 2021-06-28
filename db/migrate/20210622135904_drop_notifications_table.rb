class DropNotificationsTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :notifications
  end
end
