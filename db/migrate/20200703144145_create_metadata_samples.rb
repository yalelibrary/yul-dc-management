class CreateMetadataSamples < ActiveRecord::Migration[6.0]
  def change
    create_table :metadata_samples do |t|
      t.string :metadata_source
      t.integer :number_of_samples
      t.decimal :seconds_elapsed

      t.timestamps
    end
  end
end
