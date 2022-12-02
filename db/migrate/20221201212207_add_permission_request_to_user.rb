class AddPermissionRequestToUser < ActiveRecord::Migration[6.0]
  def change
    add_reference :users, :permission_request
  end
end
