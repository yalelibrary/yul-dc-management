class AddBatchStatus < ActiveRecord::Migration[6.0]
  def change
    add_column :batch_processes, :batch_status, :string 
  end
end
