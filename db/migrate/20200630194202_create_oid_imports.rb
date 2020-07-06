class CreateOidImports < ActiveRecord::Migration[6.0]
  def change
    create_table :oid_imports do |t|
      t.text :csv

      t.timestamps
    end
  end
end
