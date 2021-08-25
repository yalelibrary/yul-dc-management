# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:batch_process) { described_class.new(batch_action: "reassociate child oids") }
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has four child objects
  let!(:parent_object) { FactoryBot.create(:parent_object, oid: "2005512", admin_set_id: admin_set.id) }

  before do
    stub_ptiffs_and_manifests
    stub_metadata_cloud("2005512")
  end

  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
  end

  describe "child object reassociation with missing columns" do
    before do
      login_as user
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
    end

    it "does not update already existing values if column is missing" do
      visit batch_processes_path
      select("Reassociate Child Oids")
      page.attach_file("batch_process_file", Rails.root + "spec/fixtures/reassociation_example_child_object_all_columns.csv")
      click_button("Submit")
      expect(page).to have_content "Your job is queued for processing in the background"
      co = ChildObject.find(1_030_368)
      expect(co.order).to eq 1
      expect(co.label).to be_nil
      expect(co.caption).to be_nil
      expect(co.viewing_hint).to be_nil
      expect(co.parent_object.authoritative_json["title"]).to eq ["The gold pen used by Lincoln to sign the Emancipation Proclamation in the Executive Mansion, Washington, D.C., 1863 Jan 1"]
      expect(co.parent_object.call_number).to eq "GEN MSS 257"
      # csv has only child oid, parent oid, and viewing_hint
      visit batch_processes_path
      select("Reassociate Child Oids")
      page.attach_file("batch_process_file", Rails.root + "spec/fixtures/reassociation_example_child_object_missing_columns.csv")
      click_button("Submit")
      expect(page).to have_content "Your job is queued for processing in the background"
      co = ChildObject.find(1_030_368)
      expect(co.order).to eq 1
      expect(co.label).to be_nil
      expect(co.caption).to be_nil
      expect(co.viewing_hint).to eq "facing-pages"
      expect(co.parent_object.authoritative_json["title"]).to eq ["The gold pen used by Lincoln to sign the Emancipation Proclamation in the Executive Mansion, Washington, D.C., 1863 Jan 1"]
      expect(co.parent_object.call_number).to eq "GEN MSS 257"
    end
  end
end