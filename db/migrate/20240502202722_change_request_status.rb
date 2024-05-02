class ChangeRequestStatus < ActiveRecord::Migration[7.0]
  def change
    add_column :permission_requests, :request_status_new, :string, default: "Pending"

    OpenWithPermission::PermissionRequest.where(request_status: true).update_all request_status_new: "Approved"
    OpenWithPermission::PermissionRequest.where(request_status: false).update_all request_status_new: "Denied"

    remove_column :permission_requests, :request_status
    rename_column :permission_requests, :request_status_new, :request_status
  end
end
