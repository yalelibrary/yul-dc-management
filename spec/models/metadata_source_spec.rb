# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataSource, type: :model, prep_metadata_sources: true do
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
      let(:unknown_parent_object) { FactoryBot.build(:parent_object, oid: '99999999') }
      let(:ladybird_source) { FactoryBot.build(:metadata_source) }
      let(:server_error_parent) { FactoryBot.build(:parent_object, oid: '7') }

      before do
        stub_request(:get, "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/16797069?include-children=1")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "16797069.json")).read)
        stub_request(:get, "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/99999999?include-children=1")
          .to_return(status: 400, body: 'Unable to communicate with ladybird')
        stub_request(:get, "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/7?include-children=1")
          .to_return(status: 500, body: 'MetadataCloud server error')

        stub_request(:put, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/ladybird/16797069.json").to_return(status: 200)
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

      it "adds a notification if record is not found in metadata cloud" do
        expect(unknown_parent_object).to receive(:processing_failure)
        ladybird_result = ladybird_source.fetch_record(unknown_parent_object)
        expect(ladybird_result).not_to be
      end

      it 'adds an error if it receives a 5XX response' do
        expect { ladybird_source.fetch_record(server_error_parent) }.to raise_error(described_class::MetadataCloudServerError)
      end
    end
  end

  context "with vpn off" do
    let(:ladybird_source) { FactoryBot.build(:metadata_source) }
    let(:voyager_source) { FactoryBot.build(:metadata_source_voyager) }
    let(:aspace_source) { FactoryBot.build(:metadata_source_aspace) }

    before do
      stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/ladybird/0.json")
        .to_return(status: 404)
      stub_metadata_cloud("16797069", 'ladybird')
      stub_metadata_cloud("V-16797069", 'ils')
      stub_metadata_cloud("AS-16797069", 'aspace')
    end

    around do |example|
      original_vpn = ENV['VPN']
      ENV['VPN'] = ""
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
      let(:parent_object) { FactoryBot.build(:parent_object, oid: '0') }

      it "returns nil if the cached json does not exist" do
        expect(parent_object).to receive(:processing_failure)
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
