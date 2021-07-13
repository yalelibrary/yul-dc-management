# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has four child objects
  let!(:parent_object) { FactoryBot.create(:parent_object, oid: "16854285", admin_set_id: admin_set.id) }
  

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
    stub_metadata_cloud("16854285")
  end


  context "with a user with edit permissions", solr: true do
    context "deleting a batch of parent objects" do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end
      before do
        login_as user
        user.add_role(:editor, admin_set)
        stub_request(:put, "https://yul-dc-ocr-test.s3.amazonaws.com/pdfs/85/16/85/42/85/16854285.pdf")
        .to_return(status: 200, headers: { 'Content-Type' => 'text/plain' })
        # stub_request(:head, "https://yul-dc-ocr-test.s3.amazonaws.com/originals/89/45/67/89/456789.tif")
        # .to_return(status: 200, body: "", headers: {})
        # stub_request(:head, "https://yul-dc-ocr-test.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
        # .to_return(status: 200, body: "", headers: {})
      end
      
      it "deletes the parent and artifacts" do
        # perform batch delete        
        visit batch_processes_path
        select("Delete Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/delete_sample_fixture_ids.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"
        
        # parent expectations - delete parent object, pdf, manifest, and solr document
        # parent object
        expect(ParentObject.count).to eq 0
        visit "/parent_objects/#{parent_object.oid}"
        expect(page).to have_content("Parent object, oid: #{parent_object.oid}, was not found in local instance.")
        # pdf
        # byebug
        expect do
          visit 'https://yul-dc-ocr-test.s3.amazonaws.com/pdfs/85/16/85/42/85/16854285.pdf'
        end.to (status: 404)
        # manifest
        # expect(parent_object.needs_a_manifest?).to be_truthy
        # solr document
        response = solr.get 'select', params: { q: '*:*' }
        expect(response["response"]["numFound"]).to eq 0
        
        # # child expectations - delete child object, solr document
        # expect(ChildObject.count).to eq 0
        # visit "/child_objects/#{child_object.oid}"
        # expect(response).to have_http_status(:not_found)

        
        # # confirmation message
        # visit batch_processes_path
        # click_link(BatchProcess.last.id)
        # expect(page).to have_content "Parent object was successfully destroyed."
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
