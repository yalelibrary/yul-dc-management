class AddLastUpdatePreservicaToChildObject < ActiveRecord::Migration[6.0]
  def change
    add_column :child_objects, :last_preservica_update, :datetime
  end
end
