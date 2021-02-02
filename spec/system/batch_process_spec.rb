# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, js: true do
  let(:user) { FactoryBot.create(:user) }

  around do |example|
    original_path = ENV["GOOBI_MOUNT"]
    ENV["GOOBI_MOUNT"] = File.join("spec", "fixtures", "goobi", "metadata")
    example.run
    ENV["GOOBI_MOUNT"] = original_path
  end

  before do
    stub_ptiffs_and_manifests
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("2005512")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
    login_as user
    visit batch_processes_path
  end

  context "having created a parent_object via the UI" do
    before do
      stub_metadata_cloud("16057779")
      visit parent_objects_path
      click_on("New Parent Object")
      fill_in('Oid', with: "16057779")
      click_on("Create Parent object")
    end
    it "can still successfully see the batch_process page" do
      visit batch_processes_path
      click_on("View")
      expect(page.body).to have_link('View', href: "/batch_processes/#{BatchProcess.last.id}")
    end
    context "deleting a parent object" do
      it "can still load the batch_process page" do
        po = ParentObject.find(16_057_779)
        po.delete
        expect(po.destroyed?).to be true
        visit batch_processes_path
        click_on("View")
        expect(page.body).to have_link('View', href: "/batch_processes/#{BatchProcess.last.id}")
      end
    end
  end

  context "when uploading a csv" do
    it "uploads and increases csv count and gives a success message" do
      expect(BatchProcess.count).to eq 0
      page.attach_file("batch_process_file", Rails.root + "spec/fixtures/short_fixture_ids.csv")
      click_button("Submit")
      expect(BatchProcess.count).to eq 1
      expect(page).to have_content("Your job is queued for processing in the background")
      expect(BatchProcess.last.file_name).to eq "short_fixture_ids.csv"
      expect(BatchProcess.last.batch_action).to eq "create parent objects"
      expect(BatchProcess.last.output_csv).to be nil
    end

    context "outputting csv" do
      let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_034_600) }
      before do
        parent_object
      end
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end
      it "uploads a CSV of parent oids in order to create export of child objects oids and orders" do
        expect(BatchProcess.count).to eq 0
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/short_fixture_ids.csv")
        select("export child oids")
        click_button("Submit")
        expect(BatchProcess.count).to eq 1
        expect(page).to have_content("Your job is queued for processing in the background")
        expect(BatchProcess.last.file_name).to eq "short_fixture_ids.csv"
        expect(BatchProcess.last.batch_action).to eq "export child oids"
        expect(BatchProcess.last.output_csv).to include "1126257"
        click_on("View")
        expect(page).to have_link("short_fixture_ids.csv", href: "/batch_processes/#{BatchProcess.last.id}/download")
        expect(page).to have_link("short_fixture_ids_bp_#{BatchProcess.last.id}.csv", href: "/batch_processes/#{BatchProcess.last.id}/download_created")
        click_on("short_fixture_ids_bp_#{BatchProcess.last.id}.csv")
      end
    end

    context "deleting a parent object" do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end
      before do
        page.attach_file("batch_process_file", Rails.root + "spec/fixtures/short_fixture_ids.csv")
        click_button("Submit")
        po = ParentObject.find(16_854_285)
        po.destroy
        page.refresh
      end

      it "can still see the details of the import" do
        expect(page).to have_link(BatchProcess.last.id.to_s, href: "/batch_processes/#{BatchProcess.last.id}")
        expect(page).to have_content('5')
        expect(page).to have_link('View', href: "/batch_processes/#{BatchProcess.last.id}")
      end
    end
  end
  context "when uploading an xml" do
    it "uploads and increases xml count and gives a success message" do
      expect(BatchProcess.count).to eq 0
      page.attach_file("batch_process_file", fixture_path + '/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml')
      click_button("Submit")
      expect(BatchProcess.count).to eq 1
      expect(page).to have_content("Your job is queued for processing in the background")
      expect(BatchProcess.last.file_name).to eq "111860A_8394689_mets.xml"
    end

    context "deleting a parent object" do
      before do
        page.attach_file("batch_process_file", fixture_path + '/goobi/metadata/30000317_20201203_140947/111860A_8394689_mets.xml')
        click_button("Submit")
      end
      it "can still load the batch_process page" do
        po = ParentObject.find(30_000_317)
        po.delete
        expect(po.destroyed?).to be true
        visit batch_processes_path
        click_on("View")
        expect(page.body).to have_link('View', href: "/batch_processes/#{BatchProcess.last.id}")
      end
    end
  end
end
