# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has two child objects
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2005512", admin_set_id: admin_set.id) }

  before do
    stub_manifests
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

  context "with a user with edit permissions", solr: true do
    context "deleting a batch of parent objects" do
      before do
        login_as user
        user.add_role(:editor, admin_set)
      end

      it "deletes the parent and artifacts except for full text" do
        # perform batch delete
        visit batch_processes_path
        select("Delete Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/delete_parent_fixture_ids.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"

        # parent/child object delete
        expect(ParentObject.count).to eq 0
        expect(ChildObject.count).to eq 0

        visit "/parent_objects/#{parent_object.oid}"
        expect(page).to have_content("Parent object, oid: #{parent_object.oid}, was not found in local database.")

        # manifest delete
        expect(parent_object.iiif_manifest).to be_nil

        # solr document delete
        response = solr.get 'select', params: { q: '*:*' }
        expect(response["response"]["numFound"]).to eq 0

        # ptiff and pdf deletion checked in spec/requests/batch_processes_request_spec.rb:134

        # can still display a show_parent batch process page
        visit "/batch_processes/#{BatchProcess.last.id}/parent_objects/2005512"
        expect(page).to have_content "Status 2005512 deleted"
      end
    end
  end

  context "with a user without edit permissions" do
    let(:admin_user) { FactoryBot.create(:sysadmin_user) }

    context "deleting a batch of parent objects" do
      before do
        login_as admin_user
        admin_user.remove_role(:editor)
        visit batch_processes_path
      end

      it "does not permit parent to be deleted" do
        select("Delete Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/delete_parent_fixture_ids.csv")
        click_button("Submit")
        expect(ParentObject.count).to eq 1
      end
    end
  end
end
