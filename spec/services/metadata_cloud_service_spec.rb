# frozen_string_literal: true
require "rails_helper"
require "webmock"

RSpec.describe MetadataCloudService, prep_metadata_sources: true do
  let(:mcs) { described_class.new }
  let(:oid) { "16371253" }
  let(:oid_url) { "https://#{described_class.metadata_cloud_host}/metadatacloud/api/ladybird/oid/#{oid}?mediaType=json" }
  let(:short_oid_path) { Rails.root.join("spec", "fixtures", "short_fixture_ids.csv") }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  before do
    allow(PyramidalTiffFactory).to receive(:generate_ptiff_from).and_return(width: 2591, height: 4056)
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("2005512")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
  end

  context "creating a ParentObject from an import" do
    before do
      stub_metadata_cloud("16371253")
    end
    it "can create a parent_object from an array of oids" do
      expect(ParentObject.count).to eq 0
      described_class.create_parent_objects_from_oids(["16371253"], ["ladybird"])
      expect(ParentObject.count).to eq 1
      expect(ParentObject.where(oid: "16371253").first.ladybird_json).not_to be nil
      expect(ParentObject.where(oid: "16371253").first.ladybird_json).not_to be_empty
    end
  end

  context "it gets called from a rake task" do
    let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "2034600.json") }
    let(:metadata_source) { ["ladybird"] }

    it "is easy to invoke" do
      time_stamp_before = File.mtime(path_to_example_file.to_s)
      described_class.refresh_fixture_data(short_oid_path, metadata_source)
      time_stamp_after = File.mtime(path_to_example_file.to_s)
      expect(time_stamp_before).to be < time_stamp_after
    end
  end

  context "saving a Voyager record" do
    let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ils", "V-2034600.json") }
    let(:metadata_source) { ["ils"] }

    before do
      stub_metadata_cloud("V-2034600", "ils")
      stub_metadata_cloud("V-2005512", "ils")
      stub_metadata_cloud("V-16414889", "ils")
      stub_metadata_cloud("V-14716192", "ils")
      stub_metadata_cloud("V-16854285", "ils")
    end

    it "can pull voyager records" do
      time_stamp_before = File.mtime(path_to_example_file.to_s)
      described_class.refresh_fixture_data(short_oid_path, metadata_source)
      time_stamp_after = File.mtime(path_to_example_file.to_s)
      expect(time_stamp_before).to be < time_stamp_after
    end
  end

  context "saving an ArchiveSpace record" do
    let(:oid_with_aspace) { "16854285" }
    let(:metadata_source) { ["aspace"] }
    let(:oid_without_aspace) { "2034600" }

    let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "aspace", "AS-16854285.json") }
    let(:metadata_source) { ["aspace"] }

    before do
      stub_metadata_cloud("AS-16854285", "aspace")
      stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/aspace/AS-2034600.json")
        .to_return(status: 400, body: "")
      stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/aspace/AS-2005512.json")
        .to_return(status: 400, body: "")
      stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/aspace/AS-16414889.json")
        .to_return(status: 400, body: "")
      stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/aspace/AS-14716192.json")
        .to_return(status: 400, body: "")
    end

    it "can pull ArchiveSpace records" do
      time_stamp_before = File.mtime(path_to_example_file.to_s)
      described_class.refresh_fixture_data(short_oid_path, metadata_source)
      time_stamp_after = File.mtime(path_to_example_file.to_s)
      expect(time_stamp_before).to be <= time_stamp_after
    end
  end

  it "can read from a csv file" do
    expect(described_class.list_of_oids(short_oid_path)).to include "2034600"
  end

  it "can take an oid and build a metadata cloud Ladybird url" do
    expect(described_class.build_metadata_cloud_url("2034600", "ladybird").to_s).to eq "https://#{described_class.metadata_cloud_host}/metadatacloud/api/ladybird/oid/2034600?include-children=1"
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

  context "if the MetadataCloud cannot find an object" do
    let(:unfindable_oid_array) { ["17063396", "17029210"] }
    let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "17063396.json") }

    around do |example|
      original_vpn = ENV['VPN']
      ENV['VPN'] = 'true'
      example.run
      ENV['VPN'] = original_vpn
    end

    before do
      stub_request(:get, "https://#{described_class.metadata_cloud_host}/metadatacloud/api/ladybird/oid/17063396?include-children=1")
        .to_return(status: 400, body: "ex: can't connect to ladybird")
      stub_request(:get, "https://#{described_class.metadata_cloud_host}/metadatacloud/api/ladybird/oid/17029210?include-children=1")
        .to_return(status: 400, body: "ex: can't connect to ladybird")
    end

    it "does not save the response to the local filesystem" do
      expect(path_to_example_file).not_to exist
      described_class.save_json_from_oids(unfindable_oid_array, "ladybird")
      expect(path_to_example_file).not_to exist
    end
  end
end
