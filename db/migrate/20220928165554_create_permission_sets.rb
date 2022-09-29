class CreatePermissionSets < ActiveRecord::Migration[6.0]
  def change
    create_table :permission_sets do |t|
      t.text :label
      t.text :key
      t.integer :max_queue_length, default: 10

      t.timestamps
    end
  end
end
