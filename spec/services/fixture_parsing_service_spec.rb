# frozen_string_literal: true
require "rails_helper"

RSpec.describe FixtureParsingService do
  let(:oid) { "2003431" }
  let(:metadata_source) { "ladybird" }
  let(:short_oid_path) { Rails.root.join("spec", "fixtures", "short_fixture_ids.csv") }

  it "can return a hash from a fixture file" do
    data_hash = described_class.fixture_file_to_hash(oid, metadata_source)
    expect(data_hash["title"]).to include "Albergati Bible"
  end

  context "a crosswalk maintained in the database", vpn_only: false do
    let(:oid) { "2004628" }
    let(:bib) { "3163155" }
    let(:po) { FactoryBot.create(:parent_object, oid: oid, bib: bib) }
    let(:fps) { described_class.new }

    it "can update the bib" do
      po
      described_class.find_source_ids_for(oid)
      expect(ParentObject.find_by(oid: oid)["bib"]).to eq bib
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
        expect(ParentObject.find_by(oid: oid_1)["bib"]).to eq bib_1
        expect(ParentObject.find_by(oid: oid_2)["bib"]).to eq bib_2
      end
    end

    context "with an object without an aspace uri" do
      it "leaves empty values as null" do
        po
        described_class.find_source_ids_for(oid)
        expect(ParentObject.find_by(oid: oid)["barcode"].nil?).to be true
        expect(ParentObject.find_by(oid: oid)["aspace_uri"].nil?).to be true
      end
    end

    context "with an object with only an oid set that should have all other identifiers" do
      let(:oid) { "16854285" }
      let(:aspace_uri) { "/repositories/11/archival_objects/515305" }
      let(:bib) { "12307100" }
      let(:holding) { "12484205" }
      let(:item) { "10996370" }
      let(:parent_object) { FactoryBot.create(:parent_object, oid: oid) }
      let(:private_oid) { "16189097-priv" }
      let(:private_object) { FactoryBot.create(:parent_object, oid: private_oid) }
      let(:yale_only_oid) { "16189097-yale" }
      let(:yale_only_object) { FactoryBot.create(:parent_object, oid: yale_only_oid) }

      it "adds all the related ids and visibility" do
        parent_object
        described_class.find_source_ids_for(oid)
        expect(ParentObject.find_by(oid: oid)["aspace_uri"]).to eq aspace_uri
        expect(ParentObject.find_by(oid: oid)["bib"]).to eq bib
        expect(ParentObject.find_by(oid: oid)["holding"]).to eq holding
        expect(ParentObject.find_by(oid: oid)["item"]).to eq item
        expect(ParentObject.find_by(oid: oid)["visibility"]).to eq "Public"
      end

      it "adds the visibility for non-public objects" do
        private_object
        yale_only_object
        described_class.find_source_ids_for(private_oid)
        described_class.find_source_ids_for(yale_only_oid)
        expect(ParentObject.find_by(oid: private_oid)["visibility"]).to eq "Private"
        expect(ParentObject.find_by(oid: yale_only_oid)["visibility"]).to eq "Yale Community Only"
      end

      it "finds the dependent uris for an aspace object" do
        parent_object
        described_class.find_dependent_uris(oid, "ladybird")
        expect(DependentObject.find_by(parent_object_id: oid)).not_to be nil
        expect(DependentObject.find_by(parent_object_id: oid).dependent_uri).to include "/ladybird/oid/16854285"
      end
    end
  end

  it "can read from a csv file" do
    expect(described_class.build_oid_array(short_oid_path)).to include "2034600"
  end
end
