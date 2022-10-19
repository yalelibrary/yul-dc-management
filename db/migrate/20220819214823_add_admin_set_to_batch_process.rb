class AddAdminSetToBatchProcess < ActiveRecord::Migration[6.0]
  def change
    add_column :batch_processes, :admin_set, :string
  end
end
