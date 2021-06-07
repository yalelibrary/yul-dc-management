class AddDigitizationNoteToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :digitization_note, :string
  end
end
