# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }

  around do |example|
    original_path = ENV["GOOBI_MOUNT"]
    ENV["GOOBI_MOUNT"] = File.join("spec", "fixtures", "goobi", "metadata")
    example.run
    ENV["GOOBI_MOUNT"] = original_path
  end

  before do
    stub_metadata_cloud("2034600")
    stub_metadata_cloud("2005512")
    stub_metadata_cloud("16414889")
    stub_metadata_cloud("14716192")
    stub_metadata_cloud("16854285")
    login_as user
    visit batch_processes_path
  end

  context "when uploading a csv" do
    it "uploads and increases csv count and gives a success message" do
      expect(BatchProcess.count).to eq 0
      page.attach_file("batch_process_file", Rails.root + "spec/fixtures/short_fixture_ids.csv")
      click_button("Import")
      expect(BatchProcess.count).to eq 1
      expect(page).to have_content("Your records have been retrieved from the MetadataCloud. PTIFF generation, manifest generation and indexing happen in the background.")
      expect(BatchProcess.last.file_name).to eq "short_fixture_ids.csv"
      within "td.process_id" do
        expect(page).to have_link(BatchProcess.last.id.to_s, href: "/batch_processes/#{BatchProcess.last.id}")
      end
      within "td.count" do
        expect(page).to have_content('5')
      end
      within "td.view" do
        expect(page).to have_link('View', href: "/batch_processes/#{BatchProcess.last.id}")
      end
    end
  end
  context "when uploading an xml" do
    it "uploads and increases xml count and gives a success message" do
      expect(BatchProcess.count).to eq 0
      page.attach_file("batch_process_file", fixture_path + '/goobi/metadata/16172421/meta.xml')
      click_button("Import")
      expect(BatchProcess.count).to eq 1
      expect(page).to have_content("Your records have been retrieved from the MetadataCloud. PTIFF generation, manifest generation and indexing happen in the background.")
      expect(BatchProcess.last.file_name).to eq "meta.xml"
      within "td.count" do
        expect(page).to have_content('1')
      end
    end
  end
end
