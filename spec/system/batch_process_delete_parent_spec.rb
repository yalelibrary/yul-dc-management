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

  # around do |example|
  #   original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
  #   ENV["S3_SOURCE_BUCKET_NAME"] = "yul-dc-ocr-test"
  #   example.run
  #   ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
  # end

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
        # stub_request(:post, "https://yul-dc-ocr-test.s3.amazonaws.com/pdfs/85/16/85/42/85/16854285.pdf")
        # .to_return(status: 200, headers: { 'Content-Type' => 'text/plain' })
        stub_request(:post, "https://yul-dc-ocr-test.s3.amazonaws.com/originals/00/16/85/43/00/16854300.tif")
        .to_return(status: 200, body: "", headers: {})
        stub_request(:post, "https://yul-dc-ocr-test.s3.amazonaws.com/originals/85/16/85/42/85/16854285.tif")
        .to_return(status: 200, body: "", headers: {})
        stub_request(:post, "https://yul-dc-ocr-test.s3.amazonaws.com/originals/02/16/85/43/02/16854302.tif")
        .to_return(status: 200, body: "", headers: {})
        stub_request(:post, "https://yul-dc-ocr-test.s3.amazonaws.com/originals/03/16/85/43/03/16854303.tif")
        .to_return(status: 200, body: "", headers: {})
        allow(ChildObject.first).to receive(:convert_to_ptiff!).and_return(true)
        # stub_request(:post, "https://yul-dc-ocr-test.s3.amazonaws.com/ptiffs/89/45/67/89/456789.tif")
        # .to_return(status: 200, body: "", headers: {})
      end

      it "deletes the parent and artifacts" do
        # perform batch delete(passes)
        visit batch_processes_path
        byebug
        select("Delete Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/delete_sample_fixture_ids.csv")
        click_button("Submit")
        expect(page).to have_content "Your job is queued for processing in the background"

        # parent/child object delete(passes)
        expect(ParentObject.count).to eq 0
        expect(ChildObject.count).to eq 0

        visit "/parent_objects/#{parent_object.oid}"
        expect(page).to have_content("Parent object, oid: #{parent_object.oid}, was not found in local database.")

        # pdf (selenium timeout error)
        expect do
          visit 'https://yul-dc-ocr-test.s3.amazonaws.com/pdfs/85/16/85/42/85/16854285.pdf'
        end.to raise_error

        # manifest(passes)
        expect(parent_object.iiif_manifest).to be_nil

        # solr document(passes)
        response = solr.get 'select', params: { q: '*:*' }
        expect(response["response"]["numFound"]).to eq 0

        # child object delete(passes)
        expect(ChildObject.count).to eq 0
      end

      # How to check for the ptiffs when the parent object doesnt exist. Cant click the po link. Stub?
      it "leaves the ptiffs" do
        expect do
          visit 'https://yul-dc-ocr-test.s3.amazonaws.com/originals/00/16/85/43/00/16854300.tif'
        end.not_to raise_error
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
        login_as admin_user
        admin_user.remove_role(:editor)
        visit batch_processes_path
      end

      it "does not permit parent to be deleted" do
        select("Delete Parent Objects")
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/delete_sample_fixture_ids.csv")
        click_button("Submit")
        click_link(BatchProcess.last.id)
        page.refresh
        expect(page).to have_content("Skipping row [2] with parent oid: #{parent_object.oid}, user does not have permission to delete.")
      end
    end
  end
end