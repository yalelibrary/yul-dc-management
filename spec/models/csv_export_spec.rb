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
  let(:csv) do
    CSV.generate do |csv|
      csv << ['jjjjjjjjjjjj']
    end
  end
  let(:current_user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: current_user, batch_action: 'export child oids', file_name: 'batch_process') }
  let(:csv_export) { described_class.new(csv, batch_process) }
  let(:parent_batch_process) { FactoryBot.create(:batch_process, user: current_user, batch_action: 'export all parent objects by admin set', file_name: 'batch_process') }
  let(:parent_csv_export) { described_class.new(csv, parent_batch_process) }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: oid, viewing_direction: "left-to-right", display_layout: "individuals", bib: "12834515") }

  before do
    batch_process
    stub_request(:get, "https://yul-test-samples.s3.amazonaws.com/batch/job/#{batch_process.id}/")
      .to_return(status: 200, body: "these are some test words")
    stub_metadata_cloud("16172421")
    stub_ptiffs
    stub_pdfs
    parent_object
  end

  describe "exporting a CSV of child objects" do
    it "can be instantiated" do
      expect(csv_export.to_json.include?('csv')).to eq(true)
      expect(csv_export.to_json.include?('jjjjjjjj')).to eq(true)
    end

    it "has a batch process with correct batch action" do
      expect(csv_export.to_json.include?('batch_process')).to eq(true)
      expect(csv_export.to_json.include?('export child oids')).to eq(true)
    end

    it "can save a csv to S3" do
      csv_export.save
      expect(batch_process.created_file_name).to eq "batch_process_bp_#{BatchProcess.last.id}.csv"
    end
  end

  describe "exporting a CSV of parent objects" do
    it "can be instantiated" do
      expect(parent_csv_export.to_json.include?('csv')).to eq(true)
      expect(parent_csv_export.to_json.include?('jjjjjjjj')).to eq(true)
    end

    it "has a batch process with correct batch action" do
      expect(parent_csv_export.to_json.include?('batch_process')).to eq(true)
      expect(parent_csv_export.to_json.include?('export all parent objects by admin set')).to eq(true)
    end

    it "can save a csv to S3" do
      parent_csv_export.save
      expect(parent_batch_process.created_file_name).to eq "batch_process_bp_#{BatchProcess.last.id}.csv"
    end
  end
end
