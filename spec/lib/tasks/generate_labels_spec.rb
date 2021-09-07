# frozen_string_literal: true
require "rails_helper"

RSpec.describe "rake child_objects generate_labels", type: :task, prep_metadata_sources: true, prep_admin_sets: true do
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object is not in spec/fixtures/csv/full_text_staged
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2005512", admin_set_id: admin_set.id) }
  # staged parent object is in spec/fixtures/csv/full_text_staged
  let(:staged_po) { FactoryBot.create(:parent_object, oid: "30978155", admin_set_id: admin_set.id) }

  before do
    stub_metadata_cloud("2005512")
    stub_metadata_cloud("30978155")
    stub_ptiffs_and_manifests
    parent_object
    staged_po
  end

  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
  end

  it 'does not generate labels on child objects from parents not in the list' do
    Rake::Task["child_objects:generate_labels"].invoke
    co1 = parent_object.child_objects.first
    co2 = parent_object.child_objects.last
    expect(co1.label).to be_nil
    expect(co2.label).to be_nil
  end

  it 'generates labels on child objects from parents the list' do
    Rake::Task["child_objects:generate_labels"].invoke
    co1 = staged_po.child_objects.first
    co2 = staged_po.child_objects.last
    expect(co1.label).to eq 'page 1'
    expect(co2.label).to eq 'page 2'
  end
end
