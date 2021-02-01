class AddActionToBatchProcess < ActiveRecord::Migration[6.0]
  def change
    add_column :batch_processes, :batch_action, :string
    add_column :batch_processes, :output_csv, :string
  end
end
