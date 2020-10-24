class CascadeDeleteSampleFields < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :sample_fields, :metadata_samples
    add_foreign_key  :sample_fields, :metadata_samples, on_delete: :cascade
  end
end
