class CreateDependentObjects < ActiveRecord::Migration[6.0]
  def change
    create_table :dependent_objects do |t|
      t.string :dependent_uri
      t.references :parent_object

      t.timestamps
    end
  end
end
