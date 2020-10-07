class CreateBatchProcesses < ActiveRecord::Migration[6.0]
  def change
    create_table :batch_processes do |t|
      t.text :csv
      t.xml :mets_xml
      t.string :created_by
      t.bigint :oid

      t.timestamps
    end
  end
end
