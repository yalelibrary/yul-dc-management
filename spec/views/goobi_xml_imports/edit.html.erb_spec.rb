require 'rails_helper'

RSpec.describe "goobi_xml_imports/edit", type: :view do
  before(:each) do
    @goobi_xml_import = assign(:goobi_xml_import, GoobiXmlImport.create!(
      goobi_xml_import: ""
    ))
  end

  it "renders the edit goobi_xml_import form" do
    render

    assert_select "form[action=?][method=?]", goobi_xml_import_path(@goobi_xml_import), "post" do

      assert_select "input[name=?]", "goobi_xml_import[goobi_xml_import]"
    end
  end
end
