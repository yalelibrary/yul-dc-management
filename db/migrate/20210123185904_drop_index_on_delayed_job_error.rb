class DropIndexOnDelayedJobError < ActiveRecord::Migration[6.0]
  def change
    remove_index :delayed_jobs, :last_error if index_exists?(:delayed_jobs, :last_error)
  end
end
