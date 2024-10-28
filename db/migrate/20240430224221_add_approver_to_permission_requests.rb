class AddApproverToPermissionRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :permission_requests, :approver, :string
  end
end
