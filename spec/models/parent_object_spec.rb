# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model do
  before do
    prep_metadata_call
  end
  context "a newly created ParentObject with just the oid and default authoritative_metadata_source (Ladybird for now)" do
    let(:parent_object) { described_class.create(oid: "2004628") }
    before do
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2004628")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2004628.json")).read)
    end

    it "pulls from the MetadataCloud for Ladybird and not Voyager or ArchiveSpace" do
      LADYBIRD = 1
      expect(parent_object.authoritative_metadata_source_id).to eq LADYBIRD
      expect(parent_object.ladybird_json).not_to be nil
      expect(parent_object.ladybird_json).not_to be_empty
      expect(parent_object.voyager_json).to be nil
      expect(parent_object.aspace_json).to be nil
    end
  end

  context "a newly created ParentObject with Voyager as authoritative_metadata_source" do
    let(:VOYAGER) { 2 }
    let(:parent_object) { described_class.create(oid: "2004628", authoritative_metadata_source_id: VOYAGER) }
    before do
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2004628")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2004628.json")).read)
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ils/bib/3163155")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "ils", "V-2004628.json")).read)
    end

    it "pulls from the MetadataCloud for Ladybird and Voyager and not ArchiveSpace" do
      VOYAGER = 2
      expect(parent_object.authoritative_metadata_source_id).to eq VOYAGER
      expect(parent_object.ladybird_json).not_to be nil
      expect(parent_object.ladybird_json).not_to be_empty
      expect(parent_object.voyager_json).not_to be nil
      expect(parent_object.voyager_json).not_to be_empty
      expect(parent_object.aspace_json).to be nil
    end
  end

  context "a newly created ParentObject with ArchiveSpace as authoritative_metadata_source" do
    let(:ARCHIVESPACE) { 3 }
    let(:parent_object) { described_class.create(oid: "2012036", authoritative_metadata_source_id: ARCHIVESPACE) }
    before do
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/2012036")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2012036.json")).read)
      stub_request(:get, "https://metadata-api-test.library.yale.edu/metadatacloud/api/aspace/repositories/11/archival_objects/555049")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "aspace", "AS-2012036.json")).read)
    end

    it "pulls from the MetadataCloud for Ladybird and ArchiveSpace and not Voyager" do
      ARCHIVESPACE = 3
      expect(parent_object.authoritative_metadata_source_id).to eq ARCHIVESPACE # 3 is ArchiveSpace
      expect(parent_object.ladybird_json).not_to be nil
      expect(parent_object.ladybird_json).not_to be_empty
      expect(parent_object.aspace_json).not_to be nil
      expect(parent_object.aspace_json).not_to be_empty
      expect(parent_object.voyager_json).to be nil
    end
  end
end
