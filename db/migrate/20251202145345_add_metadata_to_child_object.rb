class AddMetadataToChildObject < ActiveRecord::Migration[7.0]
  def change
    add_column :child_objects, :x_resolution, :string
    add_column :child_objects, :y_resolution, :string
    add_column :child_objects, :resolution_unit, :string
    add_column :child_objects, :color_space, :string
    add_column :child_objects, :compression, :string
    add_column :child_objects, :creator, :string
    add_column :child_objects, :date_and_time_captured, :datetime
    add_column :child_objects, :make, :string
    add_column :child_objects, :model, :string
  end
end
