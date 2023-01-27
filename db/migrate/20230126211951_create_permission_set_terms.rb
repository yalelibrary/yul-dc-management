class CreatePermissionSetTerms < ActiveRecord::Migration[6.0]
  def change
    create_table :permission_set_terms do |t|
      t.integer :permission_set_id, foreign_key: true
      t.integer :activated_by_id, foreign_key: true
      t.timestamp :activated_at
      t.integer :inactivated_by_id, foreign_key: true
      t.timestamp :inactivated_at
      t.string :title
      t.text :body
      t.timestamps
    end
  end
end
