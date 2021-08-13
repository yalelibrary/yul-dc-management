# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { described_class.new }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "short_fixture_ids.csv")) }
  let(:csv_small) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "update_example_small.csv")) }
  let(:csv_missing) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "update_example_missing.csv")) }
  let(:csv_invalid) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "update_example_invalid.csv")) }

  before do
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("2005512")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
    stub_ptiffs_and_manifests
    login_as(:user)
    batch_process.user_id = user.id
  end

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    example.run
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end

  describe "batch update parent" do
    it "includes the originating user NETid" do
      batch_process.user_id = user.id
      expect(batch_process.user.uid).to eq "mk2525"
    end
  end

  context "updating a ParentObject from an import with all columns" do
    it "can update a parent_object from a csv" do
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.refresh_metadata_cloud_csv
      end.to change { ParentObject.count }.from(0).to(5)
      po_original = ParentObject.find_by(oid: 2_034_600)
      expect(po_original.aspace_uri).to be_nil
      expect(po_original.barcode).to be_nil
      expect(po_original.bib).to be_nil
      expect(po_original.digitization_note).to be_nil
      expect(po_original.display_layout).to be_nil
      expect(po_original.extent_of_digitization).to be_nil
      expect(po_original.holding).to be_nil
      expect(po_original.item).to be_nil
      expect(po_original.rights_statement).to be_nil
      expect(po_original.viewing_direction).to be_nil
      expect(po_original.visibility).to eq "Private"

      update_batch_process = described_class.new(batch_action: "update parent objects", user_id: user.id)
      expect do
        update_batch_process.file = csv_small
        update_batch_process.save
        update_batch_process.update_parent_objects
      end.not_to change { ParentObject.count }.from(5)
      po_updated = ParentObject.find_by(oid: 2_034_600)

      expect(po_updated.aspace_uri).to eq "/repositories/11/archival_objects/515305"
      expect(po_updated.barcode).to eq "39002102340669"
      expect(po_updated.bib).to eq "12307100"
      expect(po_updated.digitization_note).to eq "5678"
      expect(po_updated.display_layout).to eq "paged"
      expect(po_updated.extent_of_digitization).to eq "Completely digitized"
      expect(po_updated.holding).to eq "temporary"
      expect(po_updated.item).to eq "reel"
      expect(po_updated.rights_statement).to eq "The use of this image may be subject to the copyright law of the United States"
      expect(po_updated.viewing_direction).to eq "left-to-right"
      expect(po_updated.visibility).to eq "Public"
    end
  end

  context "updating a ParentObject from an import with some columns" do
    it "can update a parent_object from a csv" do
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.refresh_metadata_cloud_csv
      end.to change { ParentObject.count }.from(0).to(5)
      po_original = ParentObject.find_by(oid: 2_034_600)

      expect(po_original.aspace_uri).to be_nil
      expect(po_original.barcode).to be_nil
      expect(po_original.bib).to be_nil
      expect(po_original.digitization_note).to be_nil
      expect(po_original.display_layout).to be_nil
      expect(po_original.extent_of_digitization).to be_nil
      expect(po_original.holding).to be_nil
      expect(po_original.item).to be_nil
      expect(po_original.rights_statement).to be_nil
      expect(po_original.viewing_direction).to be_nil
      expect(po_original.visibility).to eq "Private"

      update_batch_process = described_class.new(batch_action: "update parent objects", user_id: user.id)
      expect do
        update_batch_process.file = csv_missing
        update_batch_process.save
        update_batch_process.update_parent_objects
      end.not_to change { ParentObject.count }.from(5)
      po_updated = ParentObject.find_by(oid: 2_034_600)

      expect(po_updated.aspace_uri).to be_nil
      expect(po_updated.barcode).to be_nil
      expect(po_updated.bib).to be_nil
      expect(po_updated.digitization_note).to be_nil
      expect(po_updated.display_layout).to eq "paged"
      expect(po_updated.extent_of_digitization).to be_nil
      expect(po_updated.holding).to be_nil
      expect(po_updated.item).to be_nil
      expect(po_updated.rights_statement).to be_nil
      expect(po_updated.viewing_direction).to be_nil
      expect(po_updated.visibility).to eq "Yale Community Only"
    end
  end

  context "updating a ParentObject from an import with invalid fields" do
    it "will not update a parent_object from a csv" do
      expect do
        batch_process.file = csv_upload
        batch_process.save
        batch_process.refresh_metadata_cloud_csv
      end.to change { ParentObject.count }.from(0).to(5)
      po_original = ParentObject.find_by(oid: 2_034_600)

      expect(po_original.aspace_uri).to be_nil
      expect(po_original.barcode).to be_nil
      expect(po_original.bib).to be_nil
      expect(po_original.digitization_note).to be_nil
      expect(po_original.display_layout).to be_nil
      expect(po_original.extent_of_digitization).to be_nil
      expect(po_original.holding).to be_nil
      expect(po_original.item).to be_nil
      expect(po_original.rights_statement).to be_nil
      expect(po_original.viewing_direction).to be_nil
      expect(po_original.visibility).to eq "Private"

      update_batch_process = described_class.new(batch_action: "update parent objects", user_id: user.id)
      expect do
        update_batch_process.file = csv_invalid
        update_batch_process.save
        update_batch_process.update_parent_objects
      end.not_to change { ParentObject.count }.from(5)
      po_updated = ParentObject.find_by(oid: 2_034_600)

      expect(po_updated.aspace_uri).to be_nil
      expect(po_updated.barcode).to be_nil
      expect(po_updated.bib).to be_nil
      expect(po_updated.digitization_note).to be_nil
      expect(po_updated.display_layout).to be_nil
      expect(po_updated.extent_of_digitization).to be_nil
      expect(po_updated.holding).to be_nil
      expect(po_updated.item).to be_nil
      expect(po_updated.rights_statement).to be_nil
      expect(po_updated.viewing_direction).to be_nil
      expect(po_updated.visibility).to eq "Private"
    end
  end
end
