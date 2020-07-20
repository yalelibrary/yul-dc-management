class CreateGoobiXmlImports < ActiveRecord::Migration[6.0]
  def change
    create_table :goobi_xml_imports do |t|
      t.xml :goobi_xml

      t.timestamps
    end
  end
end
