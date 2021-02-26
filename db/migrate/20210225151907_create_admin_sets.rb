class CreateAdminSets < ActiveRecord::Migration[6.0]
  def change
    create_table :admin_sets do |t|
      t.string :key
      t.string :label
      t.string :homepage
      t.string :summary
      t.timestamps
    end
  end
end
