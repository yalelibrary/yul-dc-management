# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true do
  let(:ladybird) { 1 }
  let(:voyager) { 2 }
  let(:aspace) { 3 }
  let(:unexpected_metadata_source) { 4 }
  before do
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/2004628.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2004628.json")).read)
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ils/V-2004628.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "ils", "V-2004628.json")).read)
  end

  context "a newly created ParentObject with an unexpected authoritative_metadata_source" do
    let(:unexpected_metadata_source) { FactoryBot.create(:metadata_source, id: 4, metadata_cloud_name: "foo", display_name: "Foo", file_prefix: "F-") }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: "2004628", authoritative_metadata_source: unexpected_metadata_source) }
    it "raises an error when trying to get the authoritative_json for an unexpected metadata source" do
      expect { parent_object.authoritative_json }.to raise_error(StandardError)
    end
  end
  context "a newly created ParentObject with just the oid and default authoritative_metadata_source (Ladybird for now)" do
    let(:parent_object) { described_class.create(oid: "2004628") }

    it "pulls from the MetadataCloud for Ladybird and not Voyager or ArchiveSpace" do
      expect(parent_object.authoritative_metadata_source_id).to eq ladybird
      expect(parent_object.ladybird_json).not_to be nil
      expect(parent_object.ladybird_json).not_to be_empty
      expect(parent_object.voyager_json).to be nil
      expect(parent_object.aspace_json).to be nil
    end
  end

  context "a newly created ParentObject with Voyager as authoritative_metadata_source" do
    let(:parent_object) { described_class.create(oid: "2004628", authoritative_metadata_source_id: voyager) }

    it "pulls from the MetadataCloud for Ladybird and Voyager and not ArchiveSpace" do
      expect(parent_object.authoritative_metadata_source_id).to eq voyager
      expect(parent_object.ladybird_json).not_to be nil
      expect(parent_object.ladybird_json).not_to be_empty
      expect(parent_object.voyager_json).not_to be nil
      expect(parent_object.voyager_json).not_to be_empty
      expect(parent_object.aspace_json).to be nil
    end

    it "can return the json from its authoritative_metadata_source" do
      expect(parent_object.authoritative_json).to eq parent_object.voyager_json
    end
  end

  context "a newly created ParentObject with ArchiveSpace as authoritative_metadata_source" do
    let(:parent_object) { described_class.create(oid: "2012036", authoritative_metadata_source_id: aspace) }
    before do
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/2012036.json")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2012036.json")).read)
      stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/aspace/AS-2012036.json")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "aspace", "AS-2012036.json")).read)
    end

    it "pulls from the MetadataCloud for Ladybird and ArchiveSpace and not Voyager" do
      expect(parent_object.authoritative_metadata_source_id).to eq aspace # 3 is ArchiveSpace
      expect(parent_object.ladybird_json).not_to be nil
      expect(parent_object.ladybird_json).not_to be_empty
      expect(parent_object.aspace_json).not_to be nil
      expect(parent_object.aspace_json).not_to be_empty
      expect(parent_object.voyager_json).to be nil
    end
  end

  context "has a shortcut for the metadata_cloud_name" do
    let(:parent_object) { described_class.create(oid: "2004628", authoritative_metadata_source_id: voyager) }
    it 'returns source name when authoritative source is set' do
      expect(parent_object.source_name).to eq 'ils'
    end

    it 'returns nil when authoritative source is not set' do
      expect(ParentObject.new(authoritative_metadata_source_id: nil).source_name).to eq nil
    end
  end

  context 'with ladybird_json' do
    let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069', ladybird_json: JSON.parse(File.read(File.join(fixture_path, "ladybird", "16797069.json")))) }

    it 'returns a ladybird url' do
      expect(parent_object.ladybird_cloud_url).to eq "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ladybird/oid/16797069"
    end

    it 'returns a voyager url' do
      expect(parent_object.voyager_cloud_url).to eq "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/ils/barcode/39002075038423?bib=3435140"
    end

    it 'returns an aspace url' do
      expect(parent_object.aspace_cloud_url).to eq "https://#{MetadataCloudService.metadata_cloud_host}/metadatacloud/api/aspace/repositories/11/archival_objects/608223"
    end
  end

  context 'without ladybird_json' do
    let(:parent_object) { FactoryBot.build(:parent_object, oid: '16797069') }

    it 'returns a voyager url' do
      expect(parent_object.voyager_cloud_url).to eq nil
    end

    it 'returns an aspace url' do
      expect(parent_object.aspace_cloud_url).to eq nil
    end
  end
end
