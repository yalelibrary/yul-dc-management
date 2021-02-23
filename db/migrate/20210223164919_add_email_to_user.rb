class AddEmailToUser < ActiveRecord::Migration[6.0]
  def change
    execute "update users set email = CONCAT(uid, '@connect.yale.edu') where email = ''";
  end
end
