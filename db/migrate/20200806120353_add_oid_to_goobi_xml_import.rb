class AddOidToGoobiXmlImport < ActiveRecord::Migration[6.0]
  def change
    add_column :goobi_xml_imports, :oid, :string
    add_index :goobi_xml_imports, :oid,                unique: false
  end
end
