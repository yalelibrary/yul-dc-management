# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:user, uid: "johnsmith2530") }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 1002, admin_set: admin_set) }
  let(:child_object) { FactoryBot.create(:child_object, oid: 1_030_368, parent_object: parent_object) }
  # let(:batch_process) do
  #   FactoryBot.create(
  #     :batch_process,
  #     user: user,
  #     csv: File.open(fixture_path + '/short_fixture_ids_with_source.csv').read,
  #     file_name: "short_fixture_ids_with_source.csv",
  #     created_at: "2020-10-08 14:17:01"
  #   )
  # end
  # let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826") }

  around do |example|
    original_path = ENV["GOOBI_MOUNT"]
    ENV["GOOBI_MOUNT"] = File.join("spec", "fixtures", "goobi", "metadata")
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    example.run
    ENV["GOOBI_MOUNT"] = original_path
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end

  before do
    stub_ptiffs_and_manifests
    # stub_metadata_cloud("2004628")
    # stub_metadata_cloud("2030006")
    # stub_metadata_cloud("2034600")
    # stub_metadata_cloud("16057779")
    # stub_metadata_cloud("2002826")
    # stub_full_text('1030368')
    # stub_full_text('1032318')
    # parent_object
  end

  context "with a user with edit permissions" do
    context "deleting a batch of parent objects" do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end
      before do
        user.add_role(:editor, admin_set)
        login_as user
        visit batch_processes_path
      end
      
      it "deletes the parent and artifacts" do
        select("Create Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/delete_sample_fixture_ids.csv")
        click_button("Submit")
        # byebug
        expect(ParentObject.count).to eq 1
        po = ParentObject.find(ParentObject.first.oid)
        co = ChildObject.find(po.child_oids)
        # visit "/manifests/#{po.oid}"
        # expect(page.status_code).to eq 200        
        visit batch_processes_path
        select("Delete Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/delete_sample_fixture_ids.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"
        
        # parent expectations
        expect(ParentObject.count).to eq 0
        # visit "/catalog/#{po.oid}"
        expect(page).to have_content "The page you were looking for doesn't exist."
        
        # pdf is deleted
        visit "/pdfs/#{po.oid}.pdf"
        # expect(page.status_code).to eq 302
        
        
        # manifest is deleted
        visit "/manifests/#{po.oid}"
        # expect(page.status_code).to eq 404
        
        # solr document is deleted
        visit "/management/parent_objects/#{po.oid}/solr_document"
        # expect(page.status_code).to eq 404
        
        # child expectations
        expect(ChildObject.count).to eq 0
        
        # solr document is deleted
        get "/management/child_objects/#{co.oid}/solr_document"
        expect(response).to have_http_status(:not_found)
        
        click_link(BatchProcess.last.id)
        expect(page).to have_content "Parent object was successfully destroyed."
      end

      it "leaves the ptiffs" do
        expect(page).to have_link("2002826")
        click_link("2002826")
        expect(page).to have_link("1011398")
        click_link("1011398")
        expect(page).to have_content("Child Batch Process Detail")
      end
      # skipping until full text feature merged
      xit "leaves the full text" do
      end
    end
  end

  context "with a user without edit permissions" do
    let(:admin_user) { FactoryBot.create(:sysadmin_user) }
    context "deleting a batch of parent objects" do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end
      before do
        login_as user
        visit batch_processes_path
      end
      
      it "does not permit parent to be deleted" do
        select("Create Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/delete_sample_fixture_ids.csv")
        click_button("Submit")
        select("Delete Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/delete_sample_fixture_ids.csv")
        click_button("Submit")
        click_link(BatchProcess.last.id)
        page.refresh
        expect(page).to have_content("#{admin_user.uid} does not have permission to create or update parent:")
      end
    end
  end
end
