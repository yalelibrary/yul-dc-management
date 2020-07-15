# frozen_string_literal: true
require "rails_helper"

RSpec.describe FixtureParsingService do
  let(:oid) { "2003431" }
  let(:metadata_source) { "ladybird" }
  let(:short_oid_path) { Rails.root.join("spec", "fixtures", "short_fixture_ids.csv") }
  before do
    prep_metadata_call
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16854285")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "16854285.json")).read)
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/barcode/39002102340669?bib=12307100")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "ils", "V-16854285.json")).read)
    stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/aspace/repositories/11/archival_objects/515305")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "aspace", "AS-16854285.json")).read)
  end

  it "can return a hash from a fixture file" do
    data_hash = described_class.fixture_file_to_hash(oid, metadata_source)
    expect(data_hash["title"]).to include "Albergati Bible"
  end

  context "a crosswalk maintained in the database", vpn_only: false do
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
      let(:private_oid) { "16189097-priv" }
      let(:private_object) { FactoryBot.create(:parent_object, oid: private_oid) }
      let(:yale_only_oid) { "16189097-yale" }
      let(:yale_only_object) { FactoryBot.create(:parent_object, oid: yale_only_oid) }
      before do
        stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16189097-priv")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "16189097-priv.json")).read)
        stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/barcode/39002113593819?bib=8330740")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ils", "V-16189097-priv.json")).read)
        stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16189097-yale")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "16189097-yale.json")).read)
        stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/barcode/39002113593819?bib=8330740")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ils", "V-16189097-yale.json")).read)
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
        expect(DependentObject.find_by(parent_object_id: private_oid).dependent_uri).to include "/ladybird/oid/16189097-priv"
        expect(DependentObject.find_by(parent_object_id: yale_only_oid).dependent_uri).to include "/ladybird/oid/16189097-yale"
      end
    end
  end

  it "can read from a csv file" do
    expect(described_class.build_oid_array(short_oid_path)).to include "2034600"
  end
end
