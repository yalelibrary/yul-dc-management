require 'rails_helper'

RSpec.describe "goobi_xml_imports/show", type: :view do
  before(:each) do
    @goobi_xml_import = assign(:goobi_xml_import, GoobiXmlImport.create!(
      goobi_xml_import: ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
  end
end
