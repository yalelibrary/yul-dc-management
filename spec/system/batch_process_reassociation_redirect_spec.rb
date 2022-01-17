# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:batch_process) { described_class.new(batch_action: "reassociate child oids") }
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has two child objects
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2005512", admin_set_id: admin_set.id) }
  let(:parent_object_2) { FactoryBot.create(:parent_object, oid: "2004550", admin_set_id: admin_set.id) }

  before do
    stub_metadata_cloud("2005512")
    stub_ptiffs_and_manifests
    parent_object
    parent_object_2
  end

  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
  end

  describe "child object reassociation with removing all children" do
    before do
      login_as user
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
      visit batch_processes_path
      select("Reassociate Child Oids")
      page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/reassociation_example_redirect_system.csv")
      click_button("Submit")
    end

    it "updates relationships and creates a redirected parent object" do
      po = ParentObject.find(parent_object.oid)
      expect(page).to have_content "Your job is queued for processing in the background"
      expect(po.redirect_to).to eq "https://collections.library.yale.edu/catalog/#{parent_object_2.oid}"
      expect(po.visibility).to eq "Redirect"
      expect(po.call_number).to be_nil
    end
  end
end
