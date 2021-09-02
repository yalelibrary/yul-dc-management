# frozen_string_literal: true
require "rails_helper"

RSpec.describe "rake child_objects generate_labels", type: :task, prep_metadata_sources: true, prep_admin_sets: true do
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has two child objects
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2005512", admin_set_id: admin_set.id) }

  before do
    stub_metadata_cloud("2005512")
    stub_ptiffs_and_manifests
    parent_object
  end

  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
  end

  it 'generates label on child object' do
    Rake::Task["child_objects:generate_labels"].invoke
    co1 = parent_object.child_objects.first
    co2 = parent_object.child_objects.last
    expect(co1.label).to eq 'page 1'
    expect(co2.label).to eq 'page 2'
  end
end
