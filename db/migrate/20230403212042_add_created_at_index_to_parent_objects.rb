class AddCreatedAtIndexToParentObjects < ActiveRecord::Migration[6.1]
  def change
    add_index  :parent_objects, :created_at
  end
end
