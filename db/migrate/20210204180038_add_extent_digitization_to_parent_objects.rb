class AddExtentDigitizationToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :extent_of_digitization, :string
  end
end
