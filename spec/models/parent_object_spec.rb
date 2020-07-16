# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model do
  before do
    prep_metadata_call
  end
  context "for previously digitized items" do
    context "a newly created ParentObject with just the oid and default authoritative_metadata_source (Ladybird for now)" do
      let(:po) { described_class.create(oid: "2004628")}
      before do
        stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2004628")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2004628.json")).read)
        po
      end

      it "pulls from the MetadataCloud for Ladybird and not Voyager or ArchiveSpace" do
        expect(po.authoritative_metadata_source_id).to eq 1 # 1 is Ladybird
        expect(po.ladybird_json).not_to be nil
        expect(po.ladybird_json).not_to be_empty
        expect(po.voyager_json).to be nil
        expect(po.aspace_json).to be nil
      end
    end

    context "a newly created ParentObject with Voyager as authoritative_metadata_source" do
      let(:po) { described_class.create(oid: "2004628", authoritative_metadata_source_id: 2)}
      before do
        stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2004628")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2004628.json")).read)
        stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/bib/3163155")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ils", "V-2004628.json")).read)
        po
      end

      it "pulls from the MetadataCloud for Ladybird and Voyager and not ArchiveSpace" do
        expect(po.authoritative_metadata_source_id).to eq 2 # 2 is Voyager
        expect(po.ladybird_json).not_to be nil
        expect(po.ladybird_json).not_to be_empty
        expect(po.voyager_json).not_to be nil
        expect(po.voyager_json).not_to be_empty
        expect(po.aspace_json).to be nil
      end
    end

    context "a newly created ParentObject with ArchiveSpace as authoritative_metadata_source" do
      let(:po) { described_class.create(oid: "2012036", authoritative_metadata_source_id: 3)}
      before do
        stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2012036")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2012036.json")).read)
        stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/aspace/repositories/11/archival_objects/555049")
          .to_return(status: 200, body: File.open(File.join(fixture_path, "aspace", "AS-2012036.json")).read)
        po
      end

      it "pulls from the MetadataCloud for Ladybird and ArchiveSpace and not Voyager" do
        expect(po.authoritative_metadata_source_id).to eq 3 # 3 is ArchiveSpace
        expect(po.ladybird_json).not_to be nil
        expect(po.ladybird_json).not_to be_empty
        expect(po.aspace_json).not_to be nil
        expect(po.aspace_json).not_to be_empty
        expect(po.voyager_json).to be nil
      end
    end
  end

  context "for newly digitized items via Goobi" do
    let(:goobi_xml) { File.open(File.join(fixture_path, "goobi", "metadata", "2012315", "meta.xml")).read }
    let(:po) { described_class.create(goobi_xml: goobi_xml)}
    before do
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2012315")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2012315.json")).read)
    end
    it "assigns the oid from the goobi_xml" do
      expect(po.oid).to eq "2012315"
    end
    it "pulls from Ladybird" do
      expect(po.authoritative_metadata_source_id).to eq 1 # 1 is Ladybird
      expect(po.ladybird_json).not_to be nil
      expect(po.ladybird_json).not_to be_empty
    end

  end
end
