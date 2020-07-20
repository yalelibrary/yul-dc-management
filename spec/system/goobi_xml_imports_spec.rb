# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Goobi Xml Imports", type: :system do
  let(:metadata_cloud_response_body_1) { File.open(File.join(fixture_path, "ladybird", "2012315.json")).read }
  let(:metadata_cloud_response_body_2) { File.open(File.join(fixture_path, "ladybird", "2046567.json")).read }
  let(:metadata_cloud_response_body_3) { File.open(File.join(fixture_path, "ladybird", "16414889.json")).read }
  let(:metadata_cloud_response_body_4) { File.open(File.join(fixture_path, "ladybird", "14716192.json")).read }
  let(:metadata_cloud_response_body_5) { File.open(File.join(fixture_path, "ladybird", "16854285.json")).read }

  before do
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2012315")
      .to_return(status: 200, body: metadata_cloud_response_body_1)
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2046567")
      .to_return(status: 200, body: metadata_cloud_response_body_2)
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16414889")
      .to_return(status: 200, body: metadata_cloud_response_body_3)
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/14716192")
      .to_return(status: 200, body: metadata_cloud_response_body_4)
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16854285")
      .to_return(status: 200, body: metadata_cloud_response_body_5)
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
  end
end
