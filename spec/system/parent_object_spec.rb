# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "ParentObjects", type: :system do
  let(:ms) { FactoryBot.create(:metadata_source) }
  let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "2034600.json") }
  let(:metadata_source) { "ladybird" }
  let(:time_stamp_before) { File.mtime(path_to_example_file.to_s) }
  let(:metadata_cloud_response_body) { File.open(path_to_example_file).read }
  context "creating a new ParentObject" do
    before do
      ms
      time_stamp_before
      visit parent_objects_path
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2034600")
        .to_return(status: 200, body: metadata_cloud_response_body)
      click_on("New Parent Object")
      fill_in('Oid', with: "2034600")
    end

    it "can create a new parent object and fetch the ladybird record from the MetadataCloud" do
      click_on("Create Parent object")
      expect(page.body).to include "Parent object was successfully created"
      time_stamp_after = File.mtime(path_to_example_file.to_s)
      expect(time_stamp_before).to be < time_stamp_after
    end

    it "has the ids from the Ladybird record" do
      click_on("Create Parent object")
      po = ParentObject.find_by(oid: "2034600")
      expect(po.bib).not_to be_empty
    end
  end
end
