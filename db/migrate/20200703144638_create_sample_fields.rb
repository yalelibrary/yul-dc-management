class CreateSampleFields < ActiveRecord::Migration[6.0]
  def change
    create_table :sample_fields do |t|
      t.string :field_name
      t.integer :field_count
      t.decimal :field_percent_of_total
      t.references :metadata_sample, null: false, foreign_key: true

      t.timestamps
    end
  end
end
