# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataSource, type: :model do
  context "with vpn on" do
    it "uses the correct url type method" do
      {
        'ladybird' => 'ladybird_cloud_url',
        'ils' => 'voyager_cloud_url',
        'aspace' => 'aspace_cloud_url'
      }.each do |k, v|
        expect(MetadataSource.new(metadata_cloud_name: k).url_type).to eq v
      end
    end

    context "with vpn mocked" do
      let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }
      let(:ladybird_source) { FactoryBot.build(:metadata_source) }

      before do
        prep_metadata_call
        stub_request(:get, "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/16797069")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "16797069.json")).read)
        stub_request(:put, "https://yul-development-samples.s3.amazonaws.com/ladybird/16797069.json").to_return(status: 200)
      end

      around do |example|
        original_vpn = ENV['VPN']
        ENV['VPN'] = 'true'
        example.run
        ENV['VPN'] = original_vpn
      end

      # Note we stub Metadata cloud, but not S3 download here proving this works
      # as intended
      it "loads the record from metadata cloud" do
        ladybird_result = ladybird_source.fetch_record(parent_object)
        expect(ladybird_result).to be
        expect(ladybird_result['uri']).to eq('/ladybird/oid/16797069')
      end
    end

    # TODO: The goal of this spec is for it to be the one section that really talks to
    # the metadata cloud for now. This should be moved to the metadata cloud validation
    # spec file once that file gets created
    context "it can talk to the metadata cloud", vpn_only: true do
      let(:oid) { "16371272" }
      let(:oid_url) { "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/#{oid}?mediaType=json" }
      let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "2034600.json") }
      let(:ladybird_source) { FactoryBot.build(:metadata_source) }

      it "can connect to the metadata cloud using basic auth" do
        expect(ladybird_source.mc_get(oid_url).to_str).to include "Manuscript, on parchment"
      end
    end
  end

  context "with vpn off" do
    let(:ladybird_source) { FactoryBot.build(:metadata_source) }
    let(:voyager_source) { FactoryBot.build(:metadata_source_voyager) }
    let(:aspace_source) { FactoryBot.build(:metadata_source_aspace) }

    before do
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/000000.json")
        .to_return(status: 404)
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/16797069.json")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "16797069.json")).read)
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ils/V-16797069.json")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "ils", "V-16797069.json")).read)
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/aspace/AS-16797069.json")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "aspace", "AS-16797069.json")).read)
    end

    around do |example|
      original_vpn = ENV['VPN']
      ENV['VPN'] = nil
      example.run
      ENV['VPN'] = original_vpn
    end

    context "with file present" do
      let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }

      it "returns the cached json if it exists" do
        ladybird_result = ladybird_source.fetch_record(parent_object)
        expect(ladybird_result).to be
        expect(ladybird_result['uri']).to eq('/ladybird/oid/16797069')
      end

      it "does not call mc_get or url_type" do
        expect(ladybird_source).not_to receive(:mc_get)
        expect(ladybird_source).not_to receive(:url_type)
        ladybird_source.fetch_record(parent_object)
      end

      it "returns aspace json for aspace metadata source type" do
        aspace_result = aspace_source.fetch_record(parent_object)
        expect(aspace_result).to be
        expect(aspace_result['uri']).to eq('/aspace/repositories/11/archival_objects/608223')
        expect(aspace_result['source']).to eq('aspace')
      end

      it "returns voyager json for voyager metadata source type" do
        voyager_result = voyager_source.fetch_record(parent_object)
        expect(voyager_result).to be
        expect(voyager_result['uri']).to eq('/ils/barcode/39002075038423?bib=3435140')
        expect(voyager_result['source']).to eq('ils')
      end
    end

    context "with file missing" do
      let(:parent_object) { FactoryBot.build(:parent_object, oid: '000000') }

      it "returns nil if the cached json does not exist" do
        ladybird_result = ladybird_source.fetch_record(parent_object)
        expect(ladybird_result).not_to be
      end

      it "does not call mc_get or url_type" do
        expect(ladybird_source).not_to receive(:mc_get)
        expect(ladybird_source).not_to receive(:url_type)
        ladybird_source.fetch_record(parent_object)
      end
    end
  end
end
