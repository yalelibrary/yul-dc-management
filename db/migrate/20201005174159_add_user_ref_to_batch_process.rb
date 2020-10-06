class AddUserRefToBatchProcess < ActiveRecord::Migration[6.0]
  def change
    add_reference :batch_processes, :user, null: false, foreign_key: true
  end
end
