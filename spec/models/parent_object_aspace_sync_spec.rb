# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:aspace) { 3 }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }

  around do |example|
    original_metadata_sample_bucket = ENV['SAMPLE_BUCKET']
    ENV['SAMPLE_BUCKET'] = "yul-dc-development-samples"
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    ENV["ACCESS_MASTER_MOUNT"] = File.join("spec", "fixtures", "images", "access_masters")
    example.run
    ENV['SAMPLE_BUCKET'] = original_metadata_sample_bucket
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
  end

  context "a newly created ParentObject with ArchiveSpace as authoritative_metadata_source" do
    let(:parent_object) do
      described_class.create(
        oid: "2012036",
        aspace_uri: "/repositories/11/archival_objects/555049",
        bib: "6805375",
        barcode: "39002091459793",
        authoritative_metadata_source_id: aspace,
        admin_set: FactoryBot.create(:admin_set),
        visibility: "Public"
      )
    end
    before do
      stub_metadata_cloud("2012036", "ladybird")
      stub_metadata_cloud("AS-2012036", "aspace")
    end

    around do |example|
      original_vpn = ENV['VPN']
      ENV['VPN'] = "true"
      example.run
      ENV['VPN'] = original_vpn
    end

    it "marks the parent private if aspace recode is restricted" do
      stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/clearly_fake_version/aspace/repositories/11/archival_objects/555049")
          .to_return(status: 400, body: File.open(File.join(fixture_path, "metadata_cloud_aspace_restricted.json")))
      allow(MetadataSource).to receive(:metadata_cloud_version).and_return("clearly_fake_version")
      expect(parent_object.visibility).to eq "Public"
      parent_object.default_fetch
      expect(parent_object.visibility).to eq "Private"
    end

    it "marks the parent private if aspace recode is deleted" do
      stub_request(:get, "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/clearly_fake_version/aspace/repositories/11/archival_objects/555049")
          .to_return(status: 400, body: File.open(File.join(fixture_path, "metadata_cloud_aspace_not_found.json")))
      allow(MetadataSource).to receive(:metadata_cloud_version).and_return("clearly_fake_version")
      expect(parent_object.visibility).to eq "Public"
      parent_object.default_fetch
      expect(parent_object.visibility).to eq "Private"
    end
  end
end
