class RemoveDuplicateUserFromBatchProcesses < ActiveRecord::Migration[6.0]
  def change
    remove_column :batch_processes, :created_by
  end
end
