class AddUsersRoleId < ActiveRecord::Migration[6.0]
  def change
    ur = UsersRole.all
    drop_table :users_roles
    create_table(:users_roles) do |t|
      t.references :user
      t.references :role
    end

    UsersRole.reset_column_information
    ur.each do |u|
      u.save!
    end
  end
end
