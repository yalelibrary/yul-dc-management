# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetsDocument, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
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
  let(:no_admin_set_file) { File.open("spec/fixtures/goobi/metadata/30000317_20201203_140947/no_admin_set.xml").read }
  let(:unknown_admin_set_file) { File.open("spec/fixtures/goobi/metadata/30000317_20201203_140947/unknown_admin_set.xml").read }
  let(:no_rights_file) { File.open("spec/fixtures/goobi/metadata/30000317_20201203_140947/no_rights_mets.xml") }
  let(:no_image_files_path) { File.join(fixture_path, "goobi", "metadata", "2012315", "no_image_files.xml") }
  let(:bad_bib_file) { File.open("spec/fixtures/goobi/metadata/30000317_20201203_140947/bad_bib.xml") }
  let(:bad_aspace_file) { File.open("spec/fixtures/goobi/metadata/30000317_20201203_140947/bad_aspace.xml") }
  let(:bad_voyager_uri_file) { File.open("spec/fixtures/goobi/metadata/30000317_20201203_140947/bad_voyager_uri.xml") }
  let(:production_mets_file) { File.open("spec/fixtures/goobi/metadata/repositories11archival_objects329771.xml") }
  let(:has_holding_file) { File.open("spec/fixtures/goobi/metadata/30000401_20201204_193140/IkSw55739ve_RA_mets.xml") }
  let(:has_caption_file) { File.open("spec/fixtures/goobi/metadata/16172421/meta.xml") }

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

    it "returns false when rights statement is not present" do
      mets_doc = described_class.new(no_rights_file)
      expect(mets_doc.valid_mets?).to be_falsey
    end

    it "returns false with a bib that contains characters other than numerals or b" do
      mets_doc = described_class.new(bad_bib_file)
      expect(mets_doc.valid_mets?).to be_falsey
    end

    it "returns false with a non-numeric holding/item/barcode" do
      mets_doc = described_class.new(bad_voyager_uri_file)
      expect(mets_doc.valid_mets?).to be_falsey
    end

    it "returns false with a malformed archivespace URI" do
      mets_doc = described_class.new(bad_aspace_file)
      expect(mets_doc.valid_mets?).to be_falsey
    end

    it "returns false with a missing admin set ownership" do
      mets_doc = described_class.new(no_admin_set_file)
      expect(mets_doc.valid_mets?).to be_falsey
    end

    it "returns false with a unknown admin set ownership" do
      mets_doc = described_class.new(unknown_admin_set_file)
      expect(mets_doc.valid_mets?).to be_falsey
    end
  end

  describe "determining if the image files described are available to the application" do
    describe "setting the environment to production" do
      around do |example|
        original_env = ENV["RAILS_ENV"]
        ENV["RAILS_ENV"] = "production"
        example.run
        ENV["RAILS_ENV"] = original_env
      end

      it "returns false with fixture paths in non-dev and non-test environments" do
        mets_doc = described_class.new(valid_goobi_xml)
        expect(mets_doc.all_images_present?).to be_truthy
        expect(mets_doc.fixture_images_in_production?).to be_truthy
        expect(mets_doc.valid_mets?).to be_falsey
      end

      it "returns true with non-fixture paths in non-dev and non-test environments" do
        mets_doc = described_class.new(production_mets_file)
        expect(mets_doc.all_images_present?).to be_falsey
        expect(mets_doc.fixture_images_in_production?).to be_falsey
      end
    end

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
    expect(mets_doc.full_metadata_cloud_url).to eq "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/1.0.1/ils/barcode/39002091118928?bib=8394689"
    expect(mets_doc.bib).to eq "8394689"
    expect(mets_doc.barcode).to eq "39002091118928"
    expect(mets_doc.holding).to be nil
    expect(mets_doc.item).to be nil
  end

  it "can identify the holding if present" do
    mets_doc = described_class.new(has_holding_file)
    expect(mets_doc.bib).to eq "1188135"
    expect(mets_doc.holding).to eq "1330141"
  end

  it "can identify the item if present" do
    mets_doc = described_class.new(valid_goobi_xml)
    allow(mets_doc).to receive(:metadata_source_path).and_return("/ils/item/9136055?bib=1169354")
    expect(mets_doc.bib).to eq "1169354"
    expect(mets_doc.item).to eq "9136055"
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
    expect(mets_doc.physical_divs.first[:label]).to eq nil
    expect(mets_doc.physical_divs.first[:order]).to eq "1"
    expect(mets_doc.physical_divs.first[:oid]).to eq "30000318"
  end

  it "returns true for a valid mets file" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.valid_mets?).to be_truthy
  end

  it "can return the combined data needed for the iiif manifest" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.combined.first[:label]).to eq nil
    expect(mets_doc.combined.first[:order]).to eq "1"
  end

  it "can return the combined data needed for the child uuid" do
    mets_doc = described_class.new(valid_goobi_xml)
    expect(mets_doc.combined.first[:child_uuid]).to eq "444d3360-bf78-4e35-9850-44ef7f832105"
    expect(mets_doc.combined.second[:child_uuid]).to eq "1234d3360-bf78-4e35-9850-44ef7f832100"
  end

  it "can return caption, type, label, id for the logical structure" do
    mets_doc = described_class.new(has_caption_file)
    expect(mets_doc.combined.first[:caption]).to eq "Swatch 1"
    expect(mets_doc.logical_divs.first[:caption]).to eq "Swatch 1"
    expect(mets_doc.logical_divs.second[:caption]).to eq nil
  end
end
