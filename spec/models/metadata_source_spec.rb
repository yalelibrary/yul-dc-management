# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataSource, type: :model do
  context "with vpn on", vpn_only: true do
    pending "specs for when vpn is on"

    context "it can talk to the metadata cloud" do
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

      it "returns aspace json for aspace metadata soruce type" do
        aspace_result = aspace_source.fetch_record(parent_object)
        expect(aspace_result).to be
        expect(aspace_result['uri']).to eq('/aspace/repositories/11/archival_objects/608223')
        expect(aspace_result['source']).to eq('aspace')
      end

      it "returns voyager json for voyager metadata soruce type" do
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
        expect(ladybird_result).to_not be
      end

      it "does not call mc_get or url_type" do
        expect(ladybird_source).not_to receive(:mc_get)
        expect(ladybird_source).not_to receive(:url_type)
        ladybird_source.fetch_record(parent_object)
      end
    end
  end
end
