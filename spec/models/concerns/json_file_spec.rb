# frozen_string_literal: true
require "rails_helper"

RSpec.describe JsonFile, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '16685691') }
  let(:path_to_example_file) { Rails.root.join("spec", "fixtures", "ladybird", "16685691.json") }
  around do |example|
    original_ocr_path = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['OCR_DOWNLOAD_BUCKET'] = 'yul-dc-ocr-test'
    perform_enqueued_jobs do
      example.run
    end
    ENV['OCR_DOWNLOAD_BUCKET'] = original_ocr_path
  end

  before do
    stub_metadata_cloud("16685691")
    stub_full_text_not_found("16686253")
    stub_ptiffs_and_manifests
  end

  it "can save a ParentObject to json" do
    time_stamp_before = File.mtime(path_to_example_file.to_s)
    parent_object.reload.to_json_file
    time_stamp_after = File.mtime(path_to_example_file.to_s)
    expect(time_stamp_before).to be < time_stamp_after
  end
end
