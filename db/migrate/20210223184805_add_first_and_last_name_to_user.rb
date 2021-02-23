class AddFirstAndLastNameToUser < ActiveRecord::Migration[6.0]
  def change
    execute "update users set first_name = 'first_name' where first_name = ''";
    execute "update users set last_name = 'last_name' where last_name = ''";
  end
end
