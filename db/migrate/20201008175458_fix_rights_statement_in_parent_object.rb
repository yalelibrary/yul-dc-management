class FixRightsStatementInParentObject < ActiveRecord::Migration[6.0]
  def change
    rename_column :parent_objects, :rights_statment, :rights_statement
  end
end
