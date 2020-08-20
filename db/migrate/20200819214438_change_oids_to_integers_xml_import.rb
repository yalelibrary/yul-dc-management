class ChangeOidsToIntegersXmlImport < ActiveRecord::Migration[6.0]
  def change
    change_column :mets_xml_imports, :oid, 'bigint USING CAST(oid AS bigint)'
  end
end
