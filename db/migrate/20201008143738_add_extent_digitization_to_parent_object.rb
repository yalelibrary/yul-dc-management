class AddExtentDigitizationToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :extent_digitization, :string
  end
end
