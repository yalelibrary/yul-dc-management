class AddParentObjectIndexes < ActiveRecord::Migration[6.0]
  def up
    add_index  :parent_objects, :aspace_uri unless index_exists?(:parent_objects, :aspace_uri)
    add_index  :parent_objects, :barcode unless index_exists?(:parent_objects, :barcode)
    add_index  :parent_objects, :bib unless index_exists?(:parent_objects, :bib)
    add_index  :parent_objects, :call_number unless index_exists?(:parent_objects, :call_number)
    add_index  :parent_objects, :holding unless index_exists?(:parent_objects, :holding)
    add_index  :parent_objects, :item unless index_exists?(:parent_objects, :item)
  end

  def down
    remove_index :parent_objects, :aspace_uri
    remove_index :parent_objects, :barcode
    remove_index :parent_objects, :bib
    remove_index :parent_objects, :call_number
    remove_index :parent_objects, :holding
    remove_index :parent_objects, :item
  end
end
