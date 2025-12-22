class AddUniqueIndexToStructures < ActiveRecord::Migration[7.0]
  def change
    add_index :structures, :id, unique: true
  end
end
