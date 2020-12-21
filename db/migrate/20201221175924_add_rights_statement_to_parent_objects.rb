class AddRightsStatementToParentObjects < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :rights_statement, :string
  end
end
