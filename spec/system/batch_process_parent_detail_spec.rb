# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Batch Process Parent detail page", type: :system, prep_metadata_sources: true, js: true do
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

  before do
    login_as user
  end

  around do |example|
    vpn = ENV["VPN"]
    ENV["VPN"] = "false"
    example.run
    ENV["VPN"] = vpn
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
    end

    describe "with a csv import" do
      it "has a link to the batch process detail page" do
        visit show_parent_batch_process_path(batch_process, 16_057_779)
        expect(page).to have_link(batch_process&.id&.to_s, href: "/batch_processes/#{batch_process.id}")
      end

      it "has a link to the parent object page" do
        visit show_parent_batch_process_path(batch_process, 16_057_779)
        expect(page).to have_link('16057779 (current record)', href: "/parent_objects/16057779")
      end

      it "shows the status of the parent object" do
        visit show_parent_batch_process_path(batch_process, 16_057_779)
        expect(page).to have_content("In progress - no failures")
      end

      it "shows when the parent object was submitted" do
        visit show_parent_batch_process_path(batch_process, 16_057_779)
        expect(page).to have_content("2020-10-08 14:17:01 UTC")
      end

      # TODO(alishaevn): determine how to mock "@notes" so the 3 specs below have content
      # it should list the value like the 3 specs above, instead of the titles
      it "shows when the metadata was fetched for the parent object" do
        visit show_parent_batch_process_path(batch_process, 16_057_779)
        expect(page).to have_content("Metadata Fetch")
      end

      it "shows when the manifest was built for the parent object" do
        visit show_parent_batch_process_path(batch_process, 16_057_779)
        expect(page).to have_content("Manifest Build")
      end

      it "shows when the metadata was indexed for the parent object" do
        visit show_parent_batch_process_path(batch_process, 16_057_779)
        expect(page).to have_content("Metadata Index")
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
