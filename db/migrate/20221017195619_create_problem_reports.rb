class CreateProblemReports < ActiveRecord::Migration[6.0]
  def change
    create_table :problem_reports do |t|
      t.integer :child_count
      t.integer :parent_count
      t.integer :problem_parent_count
      t.integer :problem_child_count
      t.text :status, index: {unique: false}

      t.timestamps
    end
  end
end
