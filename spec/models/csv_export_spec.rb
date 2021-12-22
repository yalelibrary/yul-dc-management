# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvExport, prep_metadata_sources: true do
  around do |example|
    original_manifests_base_url = ENV['IIIF_MANIFESTS_BASE_URL']
    original_image_base_url = ENV["IIIF_IMAGE_BASE_URL"]
    original_pdf_url = ENV["PDF_BASE_URL"]
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['IIIF_MANIFESTS_BASE_URL'] = "http://localhost/manifests"
    ENV['IIIF_IMAGE_BASE_URL'] = "http://localhost:8182/iiif"
    ENV["PDF_BASE_URL"] = "http://localhost/pdfs"
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    perform_enqueued_jobs do
      example.run
    end
    ENV['IIIF_MANIFESTS_BASE_URL'] = original_manifests_base_url
    ENV['IIIF_IMAGE_BASE_URL'] = original_image_base_url
    ENV["PDF_BASE_URL"] = original_pdf_url
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end
  let(:oid) { 16_172_421 }
  let(:csv) { CSV.generate do |csv|
    csv << ['jjjjjjjjjjjj']
  end }
  let(:current_user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: current_user, batch_action: 'export child oids') }
  let(:csv_export) { described_class.new(csv, batch_process) }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: oid, viewing_direction: "left-to-right", display_layout: "individuals", bib: "12834515") }

  before do
    stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/21/16/17/24/21/16172421.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "16172421.json")).read)
    stub_request(:put, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/21/16/17/24/21/16172421.json")
      .to_return(status: 200)
    stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/batch/job/id/name.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "16172421.json")).read)
    stub_request(:put, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/batch/job/id/name.json")
      .to_return(status: 200)
    stub_metadata_cloud("16172421")
    parent_object
  end

  describe "exporting a csv" do
    it "can be instantiated" do
      expect(csv_export.csv).to eq csv
    end

    it "has a batch process" do
      expect(csv_export.batch_process.class).to eq BatchProcess
    end

    it "can save a csv to S3" do
      expect(csv_export.save).to eq(true)
    end

    it "can download a csv from S3" do
      fetch_csv = JSON.parse(csv_export.fetch)
      expect(fetch_csv["label"]).to eq "Strawberry Thief fabric, made by Morris and Company "
    end
  end
end
