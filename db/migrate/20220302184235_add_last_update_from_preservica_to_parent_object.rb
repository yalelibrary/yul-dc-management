class AddLastUpdateFromPreservicaToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :last_preservica_update, :datetime
  end
end
