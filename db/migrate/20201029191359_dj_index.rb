class DjIndex < ActiveRecord::Migration[6.0]
  def change
	  #indices as indicated by dj query patterns & random googling
	  add_index :delayed_jobs, :failed_at
	  add_index :delayed_jobs, :queue
	  add_index :delayed_jobs, :last_error
	  add_index :delayed_jobs, :locked_at
	  add_index :delayed_jobs, :priority
	  add_index :delayed_jobs, [:locked_at, :failed_at]
  end
end
