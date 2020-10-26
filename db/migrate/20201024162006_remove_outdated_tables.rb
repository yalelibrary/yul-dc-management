class RemoveOutdatedTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :sample_fields do |t|
      t.string :field_name
      t.integer :field_count
      t.decimal :field_percent_of_total
      t.references :metadata_sample, null: false, foreign_key: true

      t.timestamps
    end
    drop_table :metadata_samples do |t|
      t.string :metadata_source
      t.integer :number_of_samples
      t.decimal :seconds_elapsed

      t.timestamps
    end
    drop_table :oid_imports do |t|
      t.text :csv

      t.timestamps
    end
    drop_table :mets_xml_imports do |t|
      t.xml "mets_xml"
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
      t.bigint "oid"
      t.index ["oid"], name: "index_mets_xml_imports_on_oid"
    end
  end
end
