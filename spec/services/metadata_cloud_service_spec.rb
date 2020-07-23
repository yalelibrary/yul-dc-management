# frozen_string_literal: true
require "rails_helper"
require "webmock"

WebMock.allow_net_connect!

RSpec.describe MetadataCloudService do
  let(:mcs) { described_class.new }
  let(:oid) { "16371272" }
  let(:oid_url) { "https://#{described_class.metadata_cloud_host}/metadatacloud/api/ladybird/oid/#{oid}?mediaType=json" }
  let(:short_oid_path) { Rails.root.join("spec", "fixtures", "short_fixture_ids.csv") }

  context "it needs to be on the VPN to pass", vpn_only: true do
    context "it gets called from a rake task" do
      let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "2034600.json") }
      let(:metadata_source) { "ladybird" }

      it "is easy to invoke" do
        time_stamp_before = File.mtime(path_to_example_file.to_s)
        described_class.refresh_fixture_data(short_oid_path, metadata_source)
        time_stamp_after = File.mtime(path_to_example_file.to_s)
        expect(time_stamp_before).to be < time_stamp_after
      end
    end

    context "it can talk to the metadata cloud" do
      it "can connect to the metadata cloud using basic auth" do
        expect(described_class.mc_get(oid_url).to_str).to include "Manuscript, on parchment"
      end
    end

    context "saving a Voyager record" do
      let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ils", "V-2034600.json") }
      let(:metadata_source) { "ils" }

      it "can pull voyager records" do
        time_stamp_before = File.mtime(path_to_example_file.to_s)
        described_class.refresh_fixture_data(short_oid_path, metadata_source)
        time_stamp_after = File.mtime(path_to_example_file.to_s)
        expect(time_stamp_before).to be < time_stamp_after
      end
    end

    context "saving an ArchiveSpace record" do
      let(:oid_with_aspace) { "16854285" }
      let(:metadata_source) { "aspace" }
      let(:oid_without_aspace) { "2034600" }

      let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "aspace", "AS-16854285.json") }
      let(:metadata_source) { "aspace" }

      it "can pull ArchiveSpace records" do
        time_stamp_before = File.mtime(path_to_example_file.to_s)
        described_class.refresh_fixture_data(short_oid_path, metadata_source)
        time_stamp_after = File.mtime(path_to_example_file.to_s)
        expect(time_stamp_before).to be < time_stamp_after
      end
    end
  end

  it "can read from a csv file" do
    expect(described_class.list_of_oids(short_oid_path)).to include "2034600"
  end

  context "it can build MetadataCloud urls for ParentObjects", vpn_only: false do
    it "can take an oid and build a metadata cloud Ladybird url" do
      expect(described_class.build_metadata_cloud_url("2034600", "ladybird").to_s).to eq "https://#{described_class.metadata_cloud_host}/metadatacloud/api/ladybird/oid/2034600"
    end

    it "can take an oid and build a metadata cloud bib-based Voyager url" do
      expect(described_class.build_metadata_cloud_url("2034600", "ils").to_s).to eq "https://#{described_class.metadata_cloud_host}/metadatacloud/api/ils/bib/752400"
    end

    context "with a Voyager record with a barcode" do
      let(:oid) { "16414889" }
      let(:metadata_source) { "ils" }

      it "can take an oid and build a metadata cloud barcode-based Voyager url" do
        expect(described_class.build_metadata_cloud_url(oid, metadata_source).to_s).to eq "https://#{described_class.metadata_cloud_host}/metadatacloud/api/ils/barcode/39002113596465?bib=3577942"
      end
    end

    context "with an ArchiveSpace record" do
      let(:oid_with_aspace) { "16854285" }
      let(:oid_without_aspace) { "2034600" }

      it "can take an oid and build a metadata cloud ArchiveSpace url" do
        expect(described_class.build_metadata_cloud_url(oid_with_aspace, "aspace").to_s)
          .to eq "https://#{described_class.metadata_cloud_host}/metadatacloud/api/aspace/repositories/11/archival_objects/515305"
      end

      it "does not try to retrieve a metadata cloud record if there is no ArchiveSpace record" do
        expect(described_class.build_metadata_cloud_url(oid_without_aspace, "aspace").to_s).to be_empty
      end
    end
  end

  context "if the MetadataCloud cannot find an object" do
    let(:unfindable_oid_array) { ["17063396", "17029210"] }
    let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "17063396.json") }
    before do
      stub_request(:get, "https://#{described_class.metadata_cloud_host}/metadatacloud/api/ladybird/oid/17063396")
        .to_return(status: 400, body: "ex: can't connect to ladybird")
      stub_request(:get, "https://#{described_class.metadata_cloud_host}/metadatacloud/api/ladybird/oid/17029210")
        .to_return(status: 400, body: "ex: can't connect to ladybird")
    end

    it "does not save the response to the local filesystem" do
      expect(path_to_example_file).not_to exist
      described_class.save_json_from_oids(unfindable_oid_array, "ladybird")
      expect(path_to_example_file).not_to exist
    end
  end
end
