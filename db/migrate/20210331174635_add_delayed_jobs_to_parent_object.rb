class AddDelayedJobsToParentObject < ActiveRecord::Migration[6.0]
  def change
    add_column :parent_objects, :delayed_jobs, :string, array: true, default: []
  end
end
