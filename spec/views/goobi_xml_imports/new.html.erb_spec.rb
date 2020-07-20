require 'rails_helper'

RSpec.describe "goobi_xml_imports/new", type: :view do
  before(:each) do
    assign(:goobi_xml_import, GoobiXmlImport.new(
      goobi_xml_import: ""
    ))
  end

  it "renders new goobi_xml_import form" do
    render

    assert_select "form[action=?][method=?]", goobi_xml_imports_path, "post" do

      assert_select "input[name=?]", "goobi_xml_import[goobi_xml_import]"
    end
  end
end
