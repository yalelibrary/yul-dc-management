class CreatePermissionRequestUser < ActiveRecord::Migration[6.0]
  def change
    create_table :permission_request_users do |t|
      t.string :sub
      t.string :name
      t.string :email
      t.boolean :email_verified
      t.datetime :oidc_updated_at

      t.timestamps
    end
  end
end
