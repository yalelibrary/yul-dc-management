# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true do
  let(:user) { FactoryBot.create(:user) }

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
    end
  end
end
