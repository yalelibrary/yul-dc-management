class AddRightsStatementToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :rights_statment, :string
  end
end
