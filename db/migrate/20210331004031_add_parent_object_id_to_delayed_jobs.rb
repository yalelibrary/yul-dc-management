class AddParentObjectIdToDelayedJobs < ActiveRecord::Migration[6.0]
  def change
    add_column :delayed_jobs, :parent_object_id, :integer
  end
end
