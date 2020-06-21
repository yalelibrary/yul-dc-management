class ChangeIdColumnName < ActiveRecord::Migration[6.0]
  def change
    rename_column :parent_objects, :bib, :bib
    rename_column :parent_objects, :holding, :holding
    rename_column :parent_objects, :item, :item
  end
end
