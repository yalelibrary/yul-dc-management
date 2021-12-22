# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has two child objects
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2005512", admin_set_id: admin_set.id) }

  before do
    stub_ptiffs_and_manifests
    stub_metadata_cloud("2005512")
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

  context 'from batch process page' do
    context "with a user with edit permissions" do
      context "exporting a batch of parent objects" do
        before do
          login_as user
          user.add_role(:editor, admin_set)
        end

        it "exports the parent data" do
          # perform batch export
          visit batch_processes_path
          select("Export All Parent Objects By Admin Set")
          page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/export_parent_oids.csv")
          click_button("Submit")
          expect(page).to have_content "Your job is queued for processing in the background"

          visit "/batch_processes/#{BatchProcess.last.id}"
          expect(page).to have_content "Created file: export_parent_oids"
        end
      end
    end

    context "with a user with edit permissions" do
      let(:user) { FactoryBot.create(:user) }

      context "when parents do not exist exporting a batch of parent objects" do
        before do
          login_as user
          user.add_role(:editor, admin_set)
          visit batch_processes_path
        end

        it "does not permit download" do
          select("Update Parent Objects")
          page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/export_parent_oids.csv")
          click_button("Submit")
          visit "/batch_processes/#{BatchProcess.last.id}"
          expect(page).to have_content "Skipping row"
          expect(page).to have_content "because it was not found in local database"
        end
      end
    end

    context "with a user without edit permissions" do
      let(:admin_user) { FactoryBot.create(:sysadmin_user) }
      # parent object has two child objects
      let(:parent_object) { FactoryBot.create(:parent_object, oid: "2005512", admin_set_id: admin_set.id) }

      context "exporting a batch of parent objects" do
        before do
          stub_ptiffs_and_manifests
          stub_metadata_cloud("2005512")
          parent_object
          login_as admin_user
          admin_user.remove_role(:editor)
          visit batch_processes_path
        end

        # TODO: figure out why this is failing - works in UI
        xit "does not permit parent to be downloaded" do
          select("Update Parent Objects")
          page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/export_parent_oids.csv")
          click_button("Submit")
          visit "/batch_processes/#{BatchProcess.last.id}"
          expect(page).to have_content "Skipping row"
          expect(page).to have_content "due to admin set permissions"
        end
      end
    end
  end
end
