class CreateParentObjects < ActiveRecord::Migration[6.0]
  def change
    create_table :parent_objects do |t|
      t.string :oid
      t.string :bib
      t.string :holding
      t.string :item
      t.string :barcode
      t.string :aspace_uri
      t.datetime :last_mc_update

      t.timestamps
    end
  end
end
