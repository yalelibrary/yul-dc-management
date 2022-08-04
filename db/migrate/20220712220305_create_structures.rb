class CreateStructures < ActiveRecord::Migration[6.0]
  def change
    create_table :structures do |t|
      t.boolean :top_level
      t.text :label
      t.string :description
      t.string :type
      t.string :resource_id
      t.integer :position
      t.integer :structure_id
      t.integer :parent_object_oid, foreign_key: true
      t.integer :child_object_oid, foreign_key: true

      t.timestamps
    end
  end
end
