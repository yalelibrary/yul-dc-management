# frozen_string_literal: true
require 'rails_helper'

RSpec.describe JsonFile, prep_metadata_sources: true, prep_admin_sets: true do
  let(:parent_object) do
    FactoryBot.create(:parent_object, oid: '2005512', admin_set: AdminSet.find_by_key('brbl'), authoritative_metadata_source_id: 3, aspace_uri: '/repositories/11/archival_objects/214638')
  end
  let(:path_to_example_file) { Rails.root.join('spec', 'fixtures', 'aspace', 'AS-2005512.json') }
  around do |example|
    original_ocr_path = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['OCR_DOWNLOAD_BUCKET'] = 'yul-dc-ocr-test'
    perform_enqueued_jobs do
      example.run
    end
    ENV['OCR_DOWNLOAD_BUCKET'] = original_ocr_path
  end

  before do
    stub_metadata_cloud('AS-2005512', 'aspace')
    stub_ptiffs_and_manifests
  end

  it "can save a ParentObject to json" do
    time_stamp_before = File.mtime(path_to_example_file.to_s)
    parent_object.reload.to_json_file
    time_stamp_after = File.mtime(path_to_example_file.to_s)
    expect(time_stamp_before).to be < time_stamp_after
  end
end
