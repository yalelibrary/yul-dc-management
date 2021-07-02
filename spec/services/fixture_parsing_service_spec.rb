# frozen_string_literal: true
require "rails_helper"

RSpec.describe FixtureParsingService, prep_metadata_sources: true do
  let(:oid) { "2004628" }
  let(:metadata_source) { "ladybird" }
  let(:short_oid_path) { Rails.root.join("spec", "fixtures", "short_fixture_ids.csv") }
  before do
    stub_metadata_cloud("16854285", "ladybird")
    stub_metadata_cloud("V-16854285", "ils")
    stub_metadata_cloud("AS-16854285", "aspace")
  end

  it "can return a hash from a fixture file" do
    data_hash = described_class.fixture_file_to_hash(oid, metadata_source)
    expect(data_hash["title"]).to include "Fort Vancouver"
  end

  context "a crosswalk maintained in the database" do
    let(:oid) { "2004628" }
    let(:bib) { "3163155" }
    let(:po) { FactoryBot.create(:parent_object, oid: oid, bib: bib) }
    let(:fps) { described_class.new }

    context "with an object with only an oid set that should have all other identifiers" do
      let(:oid) { "16854285" }
      let(:aspace_uri) { "/repositories/11/archival_objects/515305" }
      let(:bib) { "12307100" }
      let(:holding) { "12484205" }
      let(:item) { "10996370" }
      let(:parent_object) { FactoryBot.create(:parent_object, oid: oid) }
      let(:private_oid) { "10000016189097" }
      let(:private_object) { FactoryBot.create(:parent_object, oid: private_oid) }
      let(:yale_only_oid) { "20000016189097" }
      let(:yale_only_object) { FactoryBot.create(:parent_object, oid: yale_only_oid) }
      before do
        stub_metadata_cloud("10000016189097", "ladybird")
        stub_metadata_cloud("V-10000016189097", "ils")
        stub_metadata_cloud("20000016189097", "ladybird")
        stub_metadata_cloud("V-20000016189097", "ils")
      end

      it "finds the dependent uris for a ladybird object" do
        parent_object
        described_class.find_dependent_uri_for(oid, "ladybird")
        expect(DependentObject.find_by(parent_object_id: oid)).not_to be nil
        expect(DependentObject.find_by(parent_object_id: oid).dependent_uri).to include "/ladybird/oid/16854285"
      end

      it "finds the dependent uris for multiple objects" do
        parent_object
        private_object
        yale_only_object
        described_class.find_dependent_uris(metadata_source)
        expect(DependentObject.find_by(parent_object_id: oid).dependent_uri).to include "/ladybird/oid/16854285"
        expect(DependentObject.find_by(parent_object_id: private_oid).dependent_uri).to include "/ladybird/oid/10000016189097"
        expect(DependentObject.find_by(parent_object_id: yale_only_oid).dependent_uri).to include "/ladybird/oid/2004443"
      end
    end
  end

  it "can read from a csv file" do
    expect(described_class.build_oid_array(short_oid_path)).to include "2034600"
  end
end
