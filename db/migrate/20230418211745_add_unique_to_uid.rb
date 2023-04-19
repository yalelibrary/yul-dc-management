class AddUniqueToUid < ActiveRecord::Migration[6.1]
  def change
    add_index :users, :uid, unique: true
  end
end
