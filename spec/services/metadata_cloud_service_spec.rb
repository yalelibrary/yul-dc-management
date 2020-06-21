# frozen_string_literal: true
require "rails_helper"
require "webmock"

WebMock.allow_net_connect!

RSpec.describe MetadataCloudService do
  let(:mcs) { described_class.new }
  let(:oid) { "16371272" }
  let(:oid_url) { "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/#{oid}?mediaType=json" }
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
        expect(mcs.mc_get(oid_url).to_str).to include "Manuscript, on parchment"
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
    expect(mcs.list_of_oids(short_oid_path)).to include "2034600"
  end

  context "it can build MetadataCloud urls for ParentObjects", vpn_only: false do
    it "can take an oid and build a metadata cloud Ladybird url" do
      expect(mcs.build_metadata_cloud_url("2034600", "ladybird").to_s).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2034600"
    end

    it "can take an oid and build a metadata cloud bib-based Voyager url" do
      expect(mcs.build_metadata_cloud_url("2034600", "ils").to_s).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/bib/752400"
    end

    context "with a Voyager record with a barcode" do
      let(:oid) { "16414889" }
      let(:metadata_source) { "ils" }

      it "can take an oid and build a metadata cloud barcode-based Voyager url" do
        expect(mcs.build_metadata_cloud_url(oid, metadata_source).to_s).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/barcode/39002113596465?bib=3577942"
      end
    end

    context "with an ArchiveSpace record" do
      let(:oid_with_aspace) { "16854285" }
      let(:oid_without_aspace) { "2034600" }

      it "can take an oid and build a metadata cloud ArchiveSpace url" do
        expect(mcs.build_metadata_cloud_url(oid_with_aspace, "aspace").to_s).to eq "https://metadata-api-test.library.yale.edu/metadatacloud/api/aspace/repositories/11/archival_objects/515305"
      end

      it "does not try to retrieve a metadata cloud record if there is no ArchiveSpace record" do
        expect(mcs.build_metadata_cloud_url(oid_without_aspace, "aspace").to_s).to be_empty
      end
    end
  end

  context "a crosswalk maintained in the database", vpn_only: false do
    let(:oid) { "2004628" }
    let(:bib) { "3163155" }
    let(:po) { FactoryBot.create(:parent_object, oid: oid, bib: bib) }

    it "can update the bib" do
      po
      mcs.find_source_ids_for(oid)
      expect(po["bib"]).to eq bib
    end

    context "with all the oids" do
      let(:oid_1) { "2057976" }
      let(:bib_1) { "7039963" }
      let(:po_1) { FactoryBot.create(:parent_object, oid: oid_1, bib: bib_1) }
      let(:oid_2) { "2004628" }
      let(:bib_2) { "3163155" }
      let(:po_2) { FactoryBot.create(:parent_object, oid: oid_2, bib: bib_2) }

      it "can crosswalk multiple oids" do
        po_1
        po_2
        described_class.find_source_ids
        expect(po_1["bib"]).to eq bib_1
        expect(po_2["bib"]).to eq bib_2
      end
    end

    context "with an object without an aspace uri" do
      it "leaves empty values as null" do
        po
        mcs.find_source_ids_for(oid)
        expect(po["barcode"].nil?).to be true
        expect(po["aspace_uri"].nil?).to be true
      end
    end

    context "with an object with only an oid set that should have all other identifiers" do
      let(:oid) { "16854285" }
      let(:aspace_uri) { "/repositories/11/archival_objects/515305" }
      let(:bib) { "12307100" }
      let(:holding) { "12484205" }
      let(:item) { "10996370" }
      let(:po) { FactoryBot.create(:parent_object, oid: oid) }

      it "adds the aspace uri" do
        po
        mcs.find_source_ids_for(oid)
        expect(ParentObject.find_by(oid: oid)["aspace_uri"].nil?).to be false
        expect(ParentObject.find_by(oid: oid)["aspace_uri"]).to eq aspace_uri
        expect(ParentObject.find_by(oid: oid)["bib"]).to eq bib
        expect(ParentObject.find_by(oid: oid)["holding"]).to eq holding
        expect(ParentObject.find_by(oid: oid)["item"]).to eq item
      end
    end
  end
end
