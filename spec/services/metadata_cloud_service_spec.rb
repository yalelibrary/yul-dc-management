# frozen_string_literal: true
require "rails_helper"
require "webmock"

WebMock.allow_net_connect!

RSpec.describe MetadataCloudService, vpn_only: true do
  let(:mcs) { described_class.new }
  let(:oid_path) { Rails.root.join("spec", "fixtures", "fixture_ids.csv") }
  let(:oid_url) { "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16371272?mediaType=json" }
  let(:new_fixture_path) { Rails.root.join("spec", "fixtures", "new_json", "test_file.json") }
  let(:mc_response) { mcs.mc_get(oid_url) }
  let(:short_oid_path) { Rails.root.join("spec", "fixtures", "short_fixture_ids.csv") }
  let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "oid-2034600.json") }

  context "it gets called from a rake task" do
    it "it is easy to invoke" do
      time_stamp_before = File.mtime(path_to_example_file.to_s)
      MetadataCloudService.refresh_fixture_data(short_oid_path)
      time_stamp_after = File.mtime(path_to_example_file.to_s)
      expect(time_stamp_before).to be < time_stamp_after
    end
  end

  it "can connect to the metadata cloud using basic auth" do
    expect(mcs.mc_get(oid_url).to_str).to include "Manuscript, on parchment"
  end

  it "can read from a csv file" do
    expect(mcs.list_of_oids(oid_path)).to include "2034600"
  end

  it "can take an oid and build a metadata cloud default url" do
    expect(mcs.build_metadata_cloud_url("2004628")).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2004628?mediaType=json"
  end

  context "saving and writing to a file" do
    before do
      mcs.save_mc_json_to_file(mc_response)
    end

    it "can save a response to the local file system" do
      expect(File).to exist(new_fixture_path)
    end

    it "the new file that is created isn't empty.." do
      expect(new_fixture_path.size).not_to eq 0
    end
  end
end
