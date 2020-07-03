# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Oid CSV Import", type: :system do
  let(:metadata_cloud_response_body_1) { File.open(File.join(fixture_path, "ladybird", "2034600.json")).read }
  let(:metadata_cloud_response_body_2) { File.open(File.join(fixture_path, "ladybird", "2046567.json")).read }
  let(:metadata_cloud_response_body_3) { File.open(File.join(fixture_path, "ladybird", "16414889.json")).read }
  let(:metadata_cloud_response_body_4) { File.open(File.join(fixture_path, "ladybird", "14716192.json")).read }
  let(:metadata_cloud_response_body_5) { File.open(File.join(fixture_path, "ladybird", "16854285.json")).read }

  before do
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2034600")
      .to_return(status: 200, body: metadata_cloud_response_body_1)
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2046567")
      .to_return(status: 200, body: metadata_cloud_response_body_2)
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16414889")
      .to_return(status: 200, body: metadata_cloud_response_body_3)
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/14716192")
      .to_return(status: 200, body: metadata_cloud_response_body_4)
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16854285")
      .to_return(status: 200, body: metadata_cloud_response_body_5)
    visit management_index_path
  end

  context "with existing oids" do
    it "Does not error" do
      page.attach_file("oid_import_file", Rails.root + "spec/fixtures/short_fixture_ids.csv")
      click_button("Import")
      expect(page).to have_content("Your records have been retrieved from the MetadataCloud and are ready to be indexed to Solr.")
    end
  end

  context "when uploading a csv" do
    it "uploads and increases csv count" do
      expect(OidImport.count).to eq 0
      page.attach_file("oid_import_file", Rails.root + "spec/fixtures/short_fixture_ids.csv")
      click_button("Import")
      expect(OidImport.count).to eq 1
    end
  end
end
