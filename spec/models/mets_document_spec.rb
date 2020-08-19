# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetsDocument, type: :model, prep_metadata_sources: true do
  let(:valid_goobi_xml) { File.open(goobi_path).read }
  let(:xml_import) { FactoryBot.create(:mets_xml_import, file: File.open(goobi_path)) }
  let(:min_valid_xml_file) { File.open(File.join(fixture_path, "goobi", "min_valid_xml.xml")).read }

  around do |example|
    original_path = ENV["ACCESS_MASTER_MOUNT"]
    ENV["ACCESS_MASTER_MOUNT"] = File.join("spec", "fixtures", "goobi", "metadata")
    example.run
    ENV["ACCESS_MASTER_MOUNT"] = original_path
  end

  let(:goobi_path) { File.join(fixture_path, "goobi", "metadata", "16172421", "meta.xml") }
  let(:no_oid_file) { File.open(File.join(fixture_path, "goobi", "metadata", "16172421", "no_oid.xml")).read }
  let(:blank_oid_file) { File.open(File.join(fixture_path, "goobi", "metadata", "16172421", "blank_oid.xml")).read }
  let(:image_missing_file) { File.open(File.join(fixture_path, "goobi", "metadata", "16172421", "missing_image.xml")).read }
  let(:no_image_files_path) { File.join(fixture_path, "goobi", "metadata", "2012315", "no_image_files.xml") }

  before do
    stub_metadata_cloud("16172421")
  end

  it "can be instantiated with xml from the DB instead of a file" do
    described_class.new(xml_import.mets_xml)
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
    it "returns false for a valid METs file that points to images that are all available on the file system" do
      mets_doc = described_class.new(image_missing_file)
      expect(mets_doc.all_images_present?).to be_falsey
    end

    it "returns true for a valid METs file that points to images that are not available on the file system" do
      mets_doc = described_class.new(valid_goobi_xml)
      expect(mets_doc.all_images_present?).to be_truthy
    end
  end

  it "can return the oid" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.oid).to eq "16172421"
  end

  it "returns nil if there is no oid field in the METs document" do
    mets_doc = described_class.new(no_oid_file)
    expect(mets_doc.oid).to be_empty
  end

  it "returns an empty string if there is no oid in the METs document" do
    mets_doc = described_class.new(blank_oid_file)
    expect(mets_doc.oid).to be_empty
  end

  it "can return the uuid" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.uuid).to eq "1597600754705"
  end

  it "can return the first file id" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.files.first[:id]).to eq "FILE_0001_PRESENTATION"
  end

  it "can return the ORDERLABEL, id for the physical structure, and file id" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.physical_divs.first[:order_label]).to eq "7r"
    expect(mets_doc.physical_divs.first[:phys_id]).to eq "PHYS_0001"
    expect(mets_doc.physical_divs.first[:file_id]).to eq "FILE_0001_PRESENTATION"
  end

  it "returns true for a valid mets file" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.valid_mets?).to be_truthy
  end

  it "can return the combined data needed for the iiif manifest" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.combined.first[:order_label]).to eq "7r"
    expect(mets_doc.combined.first[:order]).to eq "1"
  end
end
