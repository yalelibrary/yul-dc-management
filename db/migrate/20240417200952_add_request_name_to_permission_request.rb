class AddRequestNameToPermissionRequest < ActiveRecord::Migration[7.0]
  def change
    add_column :permission_requests, :permission_request_user_name, :string
  end
end
