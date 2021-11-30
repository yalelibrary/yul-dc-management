class AddRedirectToParent < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :redirect_to, :text
    add_index  :parent_objects, :redirect_to unless index_exists?(:parent_objects, :redirect_to)
  end
end
