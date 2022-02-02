class ChangePreservicaUriDataType < ActiveRecord::Migration[6.0]
  def change
    change_column :parent_objects, :preservica_uri, :text
  end
end
