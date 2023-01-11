# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new(batch_action: "update IIIF manifests") }
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:csv_admin_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "valid_admin_set.csv")) }
  let(:csv_invalid_admin_set) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "invalid_admin_set.csv")) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", visibility: "Public", admin_set_id: admin_set.id) }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  before do
    # stub_metadata_cloud("2002826")
    stub_ptiffs_and_manifests
    login_as(:user)
    batch_process.user_id = user.id
    admin_set
    parent_object
    user.add_role(:editor, admin_set)
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

  context "updating IIIF manifests" do
    before do
      batch_process.file = csv_admin_set
      batch_process.save
      batch_process.update_iiif_manifests
    end
    it "can update a parent_objects manifest from a csv" do

    end
  end
end
