class AddFileNameToBatchProcess < ActiveRecord::Migration[6.0]
  def change
    add_column :batch_processes, :file_name, :string
  end
end
