class CreatePermissionRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :permission_requests do |t|
      t.boolean :request_status, default: nil
      t.text :approver_note
      t.boolean :terms_approved
      t.datetime :access_until
      t.belongs_to :permission_set
      t.belongs_to :permission_request_user
      t.belongs_to :parent_object
      t.belongs_to :user

      t.timestamps
    end
  end
end
