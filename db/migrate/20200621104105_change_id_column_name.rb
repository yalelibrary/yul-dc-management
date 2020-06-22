class ChangeIdColumnName < ActiveRecord::Migration[6.0]
  def change
    rename_column :parent_objects, :bib_id, :bib
    rename_column :parent_objects, :holding_id, :holding
    rename_column :parent_objects, :item_id, :item
  end
end
