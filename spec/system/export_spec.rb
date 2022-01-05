# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Export', type: :system, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }

  before do
    stub_ptiffs_and_manifests
    user.add_role(:viewer, admin_set)
    login_as user
    visit batch_processes_path
  end

  describe 'export child oids' do
    it 'will display a csv for download' do
      expect(BatchProcess.count).to eq 0
      page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/short_fixture_ids.csv")
      select("Export Child Oids")
      click_button("Submit")
      expect(BatchProcess.count).to eq 1
      expect(page).to have_content("Your job is queued for processing in the background")
      expect(BatchProcess.last.file_name).to eq "short_fixture_ids.csv"
      visit "/batch_processes/#{BatchProcess.last.id}"
      expect(page).to have_link 'short_fixture_ids.csv'
      expect(page).to have_link "short_fixture_ids_bp_#{BatchProcess.last.id}.csv"
    end
  end
  describe 'export all parent objects by admin set' do
    it 'will display a csv for download' do
      expect(BatchProcess.count).to eq 0
      page.attach_file("batch_process_file", Rails.root + "spec/fixtures/csv/export_parent_oids.csv")
      select("Export All Parent Objects By Admin Set")
      click_button("Submit")
      expect(BatchProcess.count).to eq 1
      expect(page).to have_content("Your job is queued for processing in the background")
      expect(BatchProcess.last.file_name).to eq "export_parent_oids.csv"
      visit "/batch_processes/#{BatchProcess.last.id}"
      expect(page).to have_link 'export_parent_oids.csv'
      expect(page).to have_link "export_parent_oids_bp_#{BatchProcess.last.id}.csv"
    end
  end
end
