class AddIndexToOidOnBatchProcess < ActiveRecord::Migration[6.0]
  def change
    add_index :batch_processes, :oid, name: "index_batch_processes_on_oid"
  end
end
