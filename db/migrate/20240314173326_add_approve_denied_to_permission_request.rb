class AddApproveDeniedToPermissionRequest < ActiveRecord::Migration[7.0]
  def change
    add_column :permission_requests, :approved_or_denied_at, :datetime
  end
end
