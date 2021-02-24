class AddFirstAndLastNameToUser < ActiveRecord::Migration[6.0]
  def change
    User.find_each do |user|
      user.first_name ||= 'first_name'
      user.last_name ||= 'last_name'
      user.save!
    end
  end
end
