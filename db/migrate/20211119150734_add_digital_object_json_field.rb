class AddDigitalObjectJsonField < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :digital_object_json, :text
  end
end