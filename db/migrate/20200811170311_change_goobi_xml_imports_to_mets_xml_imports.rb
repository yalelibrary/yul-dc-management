class ChangeGoobiXmlImportsToMetsXmlImports < ActiveRecord::Migration[6.0]
  def change
    rename_table :goobi_xml_imports, :mets_xml_imports
    rename_column :mets_xml_imports, :goobi_xml, :mets_xml
  end
end
