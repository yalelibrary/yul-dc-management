class AddNetIdToPermissionRequestUser < ActiveRecord::Migration[6.1]
  def change
    add_column :permission_request_users, :netid, :string, default: nil
  end
end
