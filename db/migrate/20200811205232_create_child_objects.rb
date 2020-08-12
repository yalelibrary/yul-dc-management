class CreateChildObjects < ActiveRecord::Migration[6.0]
  def change
    create_table :child_objects do |t|
      t.string :child_oid, index: {unique: true}
      t.string :caption
      t.integer :width
      t.integer :height
      t.integer :order
      t.references :parent_object

      t.timestamps
    end
  end
end
