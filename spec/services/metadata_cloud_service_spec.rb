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
    let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "2034600.json") }
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

    it "can take an oid and build a metadata cloud Ladybird url" do
      expect(mcs.build_metadata_cloud_url("2034600", "ladybird").to_s).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2034600?mediaType=json"
    end

    it "can take an oid and build a metadata cloud bib-based Voyager url" do
      expect(mcs.build_metadata_cloud_url("2034600", "ils").to_s).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/bib/752400?mediaType=json"
    end
  end

  context "with an ArchiveSpace record" do
    let(:oid_with_aspace) { "16854285" }
    let(:metadata_source) { "aspace" }
    let(:oid_without_aspace) { "2034600" }

    it "can take an oid and build a metadata cloud ArchiveSpace url" do
      expect(mcs.build_metadata_cloud_url(oid_with_aspace, metadata_source).to_s).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/aspace/repositories/11/archival_objects/515305?mediaType=json"
    end

    it "does not try to retrieve a metadata cloud record if there is no ArchiveSpace record" do
      expect(mcs.build_metadata_cloud_url(oid_without_aspace, metadata_source).to_s).to be_empty
    end

    let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "aspace", "AS-16854285.json") }
    let(:metadata_source) { "aspace" }

    it "can pull ArchiveSpace records" do
      time_stamp_before = File.mtime(path_to_example_file.to_s)
      MetadataCloudService.refresh_fixture_data(short_oid_path, metadata_source)
      time_stamp_after = File.mtime(path_to_example_file.to_s)
      expect(time_stamp_before).to be < time_stamp_after
    end
  end

  context "saving a Voyager record" do
    let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ils", "V-2034600.json") }
    let(:metadata_source) { "ils" }

    it "can pull voyager records" do
      time_stamp_before = File.mtime(path_to_example_file.to_s)
      MetadataCloudService.refresh_fixture_data(short_oid_path, metadata_source)
      time_stamp_after = File.mtime(path_to_example_file.to_s)
      expect(time_stamp_before).to be < time_stamp_after
    end
  end

  context "with a Voyager record with a barcode" do
    let(:oid) { "16414889" }
    let(:metadata_source) { "ils" }

    it "can take an oid and build a metadata cloud barcode-based Voyager url" do
      expect(mcs.build_metadata_cloud_url(oid, metadata_source).to_s).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/barcode/39002113596465/bib/3577942?mediaType=json"
    end
  end
end
