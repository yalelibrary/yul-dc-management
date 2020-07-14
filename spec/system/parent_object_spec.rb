# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "ParentObjects", type: :system do
  let(:ms_ladybird) { FactoryBot.create(:metadata_source) }
  let(:ms_voyager) { FactoryBot.create(:metadata_source_voyager) }
  let(:ms_aspace) { FactoryBot.create(:metadata_source_aspace) }
  let(:path_to_ladybird_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "2012036.json") }
  let(:path_to_voyager_example_file) { Rails.root.join("spec", "fixtures", "ils", "V-2012036.json") }
  let(:path_to_aspace_example_file) { Rails.root.join("spec", "fixtures", "aspace", "AS-2012036.json") }
  let(:mc_ladybird_response_body) { File.open(path_to_ladybird_example_file).read }
  let(:mc_voyager_response_body) { File.open(path_to_voyager_example_file).read }
  let(:mc_aspace_response_body) { File.open(path_to_aspace_example_file).read }

  context "creating a new ParentObject" do
    before do
      ms_ladybird
      ms_voyager
      ms_aspace
      visit parent_objects_path
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2012036")
        .to_return(status: 200, body: mc_ladybird_response_body)
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/barcode/39002091459793?bib=6805375")
        .to_return(status: 200, body: mc_voyager_response_body)
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/aspace/repositories/11/archival_objects/555049")
        .to_return(status: 200, body: mc_aspace_response_body)
      click_on("New Parent Object")
      fill_in('Oid', with: "2012036")
      click_on("Create Parent object")
    end

    it "can create a new parent object" do
      expect(page.body).to include "Parent object was successfully created"
    end

    it "saves the Ladybird record from the MC to the DB" do
      po = ParentObject.find_by(oid: "2012036")
      expect(po.ladybird_json).not_to be nil
    end

    it "has the ids from the Ladybird record" do
      po = ParentObject.find_by(oid: "2012036")
      expect(po.bib).to eq "6805375"
    end

    it "fetches the Voyager record" do
      po = ParentObject.find_by(oid: "2012036")
      expect(po.voyager_json).not_to be nil
    end

    it "fetches the ArchiveSpace record, if applicable" do
      po = ParentObject.find_by(oid: "2012036")
      expect(po.aspace_json).not_to be nil
    end
  end
end
