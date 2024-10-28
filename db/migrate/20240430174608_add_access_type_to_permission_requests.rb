class AddAccessTypeToPermissionRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :permission_requests, :change_access_type, :string
    add_column :permission_requests, :new_visibility, :string
  end
end
