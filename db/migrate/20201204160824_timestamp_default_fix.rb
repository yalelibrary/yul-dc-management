class TimestampDefaultFix < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:child_objects, :created_at, from: "2020-12-03 20:53:18", to: -> { 'CURRENT_TIMESTAMP' })
    change_column_default(:child_objects, :updated_at, from: "2020-12-03 20:53:19", to: -> { 'CURRENT_TIMESTAMP' })
  end
end
