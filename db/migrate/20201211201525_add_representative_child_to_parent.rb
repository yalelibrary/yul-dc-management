class AddRepresentativeChildToParent < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :representative_child_oid, :bigint
  end
end
