# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetsDocument, type: :model, prep_metadata_sources: true do
  let(:valid_goobi_xml) { File.open(goobi_path).read }
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:min_valid_xml_file) { File.open(File.join(fixture_path, "goobi", "min_valid_xml.xml")).read }

  around do |example|
    original_path = ENV["GOOBI_MOUNT"]
    ENV["GOOBI_MOUNT"] = File.join("spec", "fixtures", "goobi", "metadata")
    example.run
    ENV["GOOBI_MOUNT"] = original_path
  end

  let(:goobi_path) { "spec/fixtures/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml" }
  let(:no_oid_file) { File.open("spec/fixtures/goobi/metadata/30000317_20201203_140947/no_oid_mets.xml").read }
  let(:blank_oid_file) { File.open("spec/fixtures/goobi/metadata/30000317_20201203_140947/empty_oid_mets.xml").read }
  let(:image_missing_file) { File.open(File.join(fixture_path, "goobi", "metadata", "16172421", "missing_image.xml")).read }
  let(:no_image_files_path) { File.join(fixture_path, "goobi", "metadata", "2012315", "no_image_files.xml") }

  it "can be instantiated with xml from the DB instead of a file" do
    described_class.new(batch_process.mets_xml)
  end

  describe "discerning between valid and invalid METs" do
    it "returns false for a valid xml file that is not METs" do
      mets_doc = described_class.new(min_valid_xml_file)
      expect(mets_doc.valid_mets?).to be_falsey
    end

    it "returns false for a valid METs file that does not reference any images" do
      mets_doc = described_class.new(no_image_files_path)
      expect(mets_doc.valid_mets?).to be_falsey
    end
  end

  describe "determining if the image files described are available to the application" do
    it "returns false for a valid METs file that points to images that are not available on the file system" do
      mets_doc = described_class.new(image_missing_file)
      expect(mets_doc.all_images_present?).to be_falsey
    end

    it "returns true for a valid METs file that points to images that are all available on the file system" do
      mets_doc = described_class.new(valid_goobi_xml)
      expect(mets_doc.all_images_present?).to be_truthy
    end
  end

  it "can return the oid" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.oid).to eq "30000317"
  end

  it "can return the system of record API call" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.metadata_source_path).to eq "/ils/barcode/39002091118928?bib=8394689"
    expect(mets_doc.full_metadata_cloud_url).to eq "https://metadata-api-uat.library.yale.edu/metadatacloud/api/1.0.1/ils/barcode/39002091118928?bib=8394689"
  end

  it "returns nil if there is no oid field in the METs document" do
    mets_doc = described_class.new(no_oid_file)
    expect(mets_doc.oid).to be_empty
  end

  it "returns an empty string if there is no oid in the METs document" do
    mets_doc = described_class.new(blank_oid_file)
    expect(mets_doc.oid).to be_empty
  end

  it "can return the parent_uuid" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.parent_uuid).to eq "b9afab50-9f22-4505-ada6-807dd7d05733"
  end

  it "can return the label, order, child oid for the physical structure" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.physical_divs.first[:label]).to eq " - "
    expect(mets_doc.physical_divs.first[:order]).to eq "1"
    expect(mets_doc.physical_divs.first[:oid]).to eq "30000318"
  end

  it "returns true for a valid mets file" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.valid_mets?).to be_truthy
  end

  it "can return the combined data needed for the iiif manifest" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.combined.first[:label]).to eq " - "
    expect(mets_doc.combined.first[:order]).to eq "1"
  end
end
