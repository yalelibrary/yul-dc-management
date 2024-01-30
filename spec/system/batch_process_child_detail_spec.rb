# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Batch Process Child detail page', type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  context 'with expected success with a csv import', skip_db_cleaner: true do
    let(:user) { FactoryBot.create(:user, uid: 'johnsmith2530') }
    let(:brbl) { AdminSet.find_by_key('brbl')  }
    let(:sml) { AdminSet.find_by_key('sml') }
    let(:batch_process) do
      FactoryBot.create(
        :batch_process,
        user_id: user.id,
        csv: File.open(fixture_path + '/csv/shorter_fixture_ids.csv').read,
        file_name: 'shorter_fixture_ids.csv',
        created_at: '2020-10-08 14:17:01'
      )
    end

    around do |example|
      access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
      ENV["ACCESS_MASTER_MOUNT"] = "/data"
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      perform_enqueued_jobs do
        example.run
      end
      ENV["ACCESS_MASTER_MOUNT"] = access_master_mount
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
    before do
      stub_metadata_cloud('2005512')
      stub_ptiffs_and_manifests
      login_as user
      batch_process.save!
    end

    it 'has a link to the batch process detail page' do
      parent_oid = batch_process.parent_objects.last.oid
      child_oid = batch_process.parent_objects.last.child_objects.first.oid

      expect(BatchProcess.all.count).to eq 1
      visit show_child_batch_process_path(child_oid: child_oid, id: batch_process.id, oid: parent_oid)
      # has a link to the batch process detail page
      expect(page).to have_link(batch_process&.id&.to_s, href: "/batch_processes/#{batch_process.id}")
      # has a link to the parent object page
      expect(page).to have_link(parent_oid.to_s, href: "/batch_processes/#{batch_process.id}/parent_objects/#{parent_oid}")
      # has a link to the child object page
      expect(page).to have_link("#{child_oid} (current record)", href: "/child_objects/#{child_oid}")
      # shows the status of the child object
      expect(page).to have_content('Complete')
      # shows the duration of the batch process
      expect(page).to have_content('seconds')
    end
  end
end
