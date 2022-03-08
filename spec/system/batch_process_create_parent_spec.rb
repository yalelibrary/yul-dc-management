# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }

  before do
    stub_manifests
    stub_metadata_cloud("AS-200000000", "aspace")
  end

  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
  end

  context "with a user with edit permissions", solr: true do
    context "creating a parent object" do
      before do
        login_as user
        user.add_role(:editor, admin_set)
      end

      it "deletes the parent and artifacts except for full text" do
        # perform batch create
        visit batch_processes_path
        select("Create Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/preservica_parent_with_children.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"

        # parent/child object create
        expect(ParentObject.count).to eq 1
        expect(ChildObject.count).to eq 0

        visit "/batch_processes/#{BatchProcess.last.id}"
        expect(page).to have_content "Status: View Messages"
        expect(page).to have_content "Child Objects not created because tifs were not found at URI provided"
      end
    end
  end
end
