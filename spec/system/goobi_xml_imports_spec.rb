# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Goobi Xml Imports", type: :system do
  let(:metadata_cloud_response_body_1) { File.open(File.join(fixture_path, "ladybird", "2012315.json")).read }

  before do
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2012315")
      .to_return(status: 200, body: metadata_cloud_response_body_1)
  end

  context "when uploading a Goobi xml" do
    it "uploads and increases GoobiImport count" do
      visit new_goobi_xml_import_path
      expect(GoobiXmlImport.count).to eq 0
      page.attach_file("goobi_xml_import_file", fixture_path + "/goobi/metadata/2012315/meta.xml")
      click_button("Import")
      expect(GoobiXmlImport.count).to eq 1
      expect(GoobiXmlImport.last.goobi_xml).not_to eq nil
      expect(GoobiXmlImport.last.goobi_xml).not_to be_empty
    end

    it "gives a success message when uploading a valid Goobi METs file" do
      visit new_goobi_xml_import_path
      page.attach_file("goobi_xml_import_file", fixture_path + "/goobi/metadata/2012315/meta.xml")
      click_button("Import")
      expect(page.body).to include "Goobi xml import was successfully created."
    end
  end

  context "when uploading non-valid Goobi xml" do
    it "gives a failure message when upload fails" do
      visit new_goobi_xml_import_path
      page.attach_file("goobi_xml_import_file", fixture_path + "/goobi/metadata/2012315/meta_no_image_files.xml")
      click_button("Import")
      expect(page.body).not_to include "Goobi xml import was successfully created."
      expect(page.body).to include "File must be a valid Goobi METs file"
    end
  end
end
