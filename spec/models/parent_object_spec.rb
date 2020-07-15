# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model do
  before do
    prep_metadata_call
  end
  context "a newly created ParentObject with just the oid" do
    let(:po) { described_class.create(oid: "2004628")}
    before do

      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2004628")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2004628.json")).read)
      po
    end

    it "pulls from the MetadataCloud for the source of authority" do
      expect(po.authoritative_metadata_source_id).to eq 1 # 1 is Ladybird
      expect(po.ladybird_json).not_to be nil
      expect(po.ladybird_json).not_to be_empty
    end
  end
end
