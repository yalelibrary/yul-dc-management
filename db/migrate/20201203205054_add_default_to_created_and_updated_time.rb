class AddDefaultToCreatedAndUpdatedTime < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:child_objects, :created_at, from: nil, to: -> { 'CURRENT_TIMESTAMP' })
    change_column_default(:child_objects, :updated_at, from: nil, to: -> { 'CURRENT_TIMESTAMP' })
  end
end
