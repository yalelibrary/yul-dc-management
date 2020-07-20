require 'rails_helper'

RSpec.describe "goobi_xml_imports/index", type: :view do
  before(:each) do
    assign(:goobi_xml_imports, [
      GoobiXmlImport.create!(
        goobi_xml_import: ""
      ),
      GoobiXmlImport.create!(
        goobi_xml_import: ""
      )
    ])
  end

  it "renders a list of goobi_xml_imports" do
    render
    assert_select "tr>td", text: "".to_s, count: 2
  end
end
