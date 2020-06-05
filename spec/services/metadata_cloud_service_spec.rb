# frozen_string_literal: true
require "rails_helper"
require "webmock"

WebMock.allow_net_connect!

RSpec.describe MetadataCloudService, vpn_only: true do
  let(:mcs) { described_class.new }
  let(:oid) { "16371272" }
  let(:oid_url) { "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/#{oid}?mediaType=json" }
  let(:short_oid_path) { Rails.root.join("spec", "fixtures", "short_fixture_ids.csv") }

  context "it gets called from a rake task" do
    let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "oid-2034600.json") }
    let(:metadata_source) { "ladybird" }

    it "is easy to invoke" do
      time_stamp_before = File.mtime(path_to_example_file.to_s)
      MetadataCloudService.refresh_fixture_data(short_oid_path, metadata_source)
      time_stamp_after = File.mtime(path_to_example_file.to_s)
      expect(time_stamp_before).to be < time_stamp_after
    end
  end

  context "it can talk to the metadata cloud" do
    it "can connect to the metadata cloud using basic auth" do
      expect(mcs.mc_get(oid_url).to_str).to include "Manuscript, on parchment"
    end

    it "can read from a csv file" do
      expect(mcs.list_of_oids(short_oid_path)).to include "2034600"
    end

    it "can take an oid and build a metadata cloud default url" do
      expect(mcs.build_metadata_cloud_url("2034600", "ladybird")).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2034600?mediaType=json"
    end

    it "can take an oid and build a metadata cloud bib-based Voyager url" do
      expect(mcs.build_metadata_cloud_url("2034600", "ils")).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/bib/752400?mediaType=json"
    end
  end

end
