# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "METS Xml Imports", type: :system, prep_metadata_sources: true do

  before do
    stub_metadata_cloud("2012315")
  end

  context "when uploading a METS xml" do
    it "uploads and increases MetsImport and ParentObject count" do
      visit new_mets_xml_import_path
      expect(MetsXmlImport.count).to eq 0
      expect(ParentObject.count).to eq 0
      page.attach_file("mets_xml_import_file", fixture_path + "/goobi/metadata/2012315/meta.xml")
      click_button("Import")
      expect(MetsXmlImport.count).to eq 1
      expect(ParentObject.count).to eq 1
      expect(MetsXmlImport.last.mets_xml).not_to eq nil
      expect(MetsXmlImport.last.mets_xml).not_to be_empty
    end

    it "gives a success message when uploading a valid Goobi METs file" do
      visit new_mets_xml_import_path
      page.attach_file("mets_xml_import_file", fixture_path + "/goobi/metadata/2012315/meta.xml")
      click_button("Import")
      expect(page.body).to include "METS xml import was successfully created."
    end
  end

  context "when uploading non-valid Goobi xml" do
    it "gives a failure message when upload fails" do
      visit new_mets_xml_import_path
      page.attach_file("mets_xml_import_file", fixture_path + "/goobi/metadata/2012315/meta_no_image_files.xml")
      click_button("Import")
      expect(page.body).not_to include "METS xml import was successfully created."
      expect(page.body).to include "File must be a valid METs file"
    end
  end
end
