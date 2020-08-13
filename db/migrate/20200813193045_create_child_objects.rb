class CreateChildObjects < ActiveRecord::Migration[6.0]
  def change
    create_table :child_objects, id: false, primary_key: :child_oid do |t|
      t.integer :child_oid, index: {unique: true}
      t.string :caption
      t.integer :width
      t.integer :height
      t.integer :order
      t.references :parent_object_oid, references: :parent_objects, null: false

      t.timestamps
    end

    rename_column :child_objects, :parent_object_oid_id, :parent_object_oid
    add_foreign_key :child_objects, :parent_objects, column: 'parent_object_oid', primary_key: 'oid', on_delete: :cascade
  end
end
