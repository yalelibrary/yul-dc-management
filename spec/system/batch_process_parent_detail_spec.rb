# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Batch Process Parent detail page", type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:user, uid: "johnsmith2530") }
  let(:batch_process) do
    FactoryBot.create(
      :batch_process,
      user: user,
      csv: File.open(fixture_path + '/small_short_fixture_ids.csv').read,
      file_name: "small_short_fixture_ids.csv",
      created_at: "2020-10-08 14:17:01"
    )
  end

  around do |example|
    original_image_bucket = ENV["S3_SOURCE_BUCKET_NAME"]
    ENV["S3_SOURCE_BUCKET_NAME"] = "yale-test-image-samples"
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    perform_enqueued_jobs do
      example.run
    end
    ENV["S3_SOURCE_BUCKET_NAME"] = original_image_bucket
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end

  describe "with a failure" do
    before do
      batch_process
      # ugh, why is it so hard to fake a failure?
    end

    xit "sees the failures on the parent object for that batch process" do
      s3_double = class_double("S3Service")
      allow(s3_double).to receive(:download).and_return(nil)
      visit show_parent_batch_process_path(batch_process, 16_057_779)
      expect(page.body).to include("failed")
    end
  end

  describe "with expected success" do
    before do
      stub_metadata_cloud("2004628")
      stub_metadata_cloud("2030006")
      stub_metadata_cloud("2034600")
      stub_metadata_cloud("16057779")
      stub_metadata_cloud("15234629")
      stub_ptiffs_and_manifests
      login_as user
      visit show_parent_batch_process_path(batch_process, 16_057_779)
    end

    describe "with a csv import" do
      describe "running the background jobs" do
        around do |example|
          perform_enqueued_jobs do
            example.run
          end
        end
        it "has a child object id" do
          expect(page).to have_content("16057781")
        end
      end
      it "has a link to the batch process detail page" do
        expect(page).to have_link(batch_process&.id&.to_s, href: "/batch_processes/#{batch_process.id}")
      end

      it "has a link to the parent object page" do
        expect(page).to have_link('16057779 (current record)', href: "/parent_objects/16057779")
      end

      it "shows the status of the parent object" do
        expect(page).to have_content("Complete")
      end

      it "shows when the parent object was submitted" do
        expect(page).to have_content("2020-10-08 14:17:01 UTC")
      end

      # TODO(alishaevn): determine how to mock "@notes" so the 3 specs below have content
      # it should list the value like the 3 specs above, instead of the titles
      it "has labels for the ingest steps for the parent object" do
        expect(page).to have_content("Metadata Fetched")
        expect(page).to have_content("Manifest Saved")
        expect(page).to have_content("Solr Indexed")
        expect(page).to have_content("PDF Generated")
      end

      describe "after deleting a parent object" do
        before do
          batch_process
          perform_enqueued_jobs
          po = ParentObject.find(16_057_779)
          po.destroy
        end

        it "can still display a show_parent page" do
          visit show_parent_batch_process_path(batch_process, 16_057_779)
        end
      end
    end
  end
end
