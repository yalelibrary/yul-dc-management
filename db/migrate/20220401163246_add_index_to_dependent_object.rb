class AddIndexToDependentObject < ActiveRecord::Migration[6.0]
  def change
    add_index  :dependent_objects, :dependent_uri unless index_exists?(:dependent_objects, :dependent_uri)
  end
end
