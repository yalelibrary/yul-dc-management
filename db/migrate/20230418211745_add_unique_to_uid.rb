class AddUniqueToUid < ActiveRecord::Migration[6.1]
  def change
    User.where.not(id:User.select("MAX(id) as id").group(:uid).map(&:id)).each { |u| u.uid = "#{u.uid}__"; u.save }
    add_index :users, :uid, unique: true
  end
end
