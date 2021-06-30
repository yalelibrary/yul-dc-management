class AddCallNumberToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :call_number, :string
  end
end
