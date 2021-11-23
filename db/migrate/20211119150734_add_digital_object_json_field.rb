class AddDigitalObjectJsonField < ActiveRecord::Migration[6.0]
  def change
    create_table :digital_object_jsons do |t|
      t.text :json
      t.references :parent_object
      t.timestamps
    end
  end
end