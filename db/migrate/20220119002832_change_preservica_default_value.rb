class ChangePreservicaDefaultValue < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:parent_objects, :digital_object_source, "None")
  end
end
