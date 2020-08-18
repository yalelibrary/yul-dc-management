# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Oid CSV Import", type: :system, prep_metadata_sources: true do
  before do
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("2005512")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
    visit root_path
  end

  context "when uploading a csv" do
    it "uploads and increases csv count and gives a success message" do
      expect(OidImport.count).to eq 0
      page.attach_file("oid_import_file", Rails.root + "spec/fixtures/short_fixture_ids.csv")
      click_button("Import")
      expect(OidImport.count).to eq 1
      expect(page).to have_content("Your records have been retrieved from the MetadataCloud and are ready to be indexed to Solr.")
    end
  end
end
