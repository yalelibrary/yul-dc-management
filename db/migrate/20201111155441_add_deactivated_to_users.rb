class AddDeactivatedToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :deactivated, :bool, default:  false
  end
end
