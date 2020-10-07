class ChangeParentObjectDefaultsForManifests < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:parent_objects, :reading_direction, from: "ltr", to: nil)
    change_column_default(:parent_objects, :pagination, from: "individuals", to: nil)
  end
end
