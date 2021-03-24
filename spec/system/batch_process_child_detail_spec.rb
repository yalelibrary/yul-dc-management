# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Batch Process Child detail page', type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:user, uid: 'johnsmith2530') }
  let(:brbl) { AdminSet.find_by_key('brbl') }
  let(:sml) { AdminSet.find_by_key('sml') }
  # let(:parent_object) { FactoryBot.create(:parent_object, oid: 16_057_779, admin_set: brbl) }
  # let(:child_object) { FactoryBot.create(:child_object, parent_object: parent_object) }
  let(:batch_process) do
    FactoryBot.create(
      :batch_process,
      user: user,
      csv: File.open(fixture_path + '/small_short_fixture_ids.csv').read,
      file_name: 'small_short_fixture_ids.csv',
      created_at: '2020-10-08 14:17:01'
    )
  end

  describe 'with expected success' do
    let(:child_oid) { batch_process.parent_objects.first.child_objects.first.oid }
    let(:parent_oid) { batch_process.parent_objects.first.oid }

    around do |example|
      access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
      ENV["ACCESS_MASTER_MOUNT"] = "/data"
      perform_enqueued_jobs do
        example.run
      end
      ENV["ACCESS_MASTER_MOUNT"] = access_master_mount
    end
    before do
      stub_metadata_cloud('16057779')
      stub_ptiffs_and_manifests
      login_as user
      batch_process
    end

    describe 'with a csv import' do
      before do
        visit show_child_batch_process_path(child_oid: child_oid, id: batch_process.id, oid: parent_oid)
      end

      it 'has a link to the batch process detail page' do
        expect(page).to have_link(batch_process&.id&.to_s, href: "/batch_processes/#{batch_process.id}")
      end

      it 'has a link to the parent object page' do
        expect(page).to have_link(parent_oid.to_s, href: "/batch_processes/#{batch_process.id}/parent_objects/#{parent_oid}")
      end

      it 'has a link to the child object page' do
        expect(page).to have_link("#{child_oid} (current record)", href: "/child_objects/#{child_oid}")
      end

      it 'shows the status of the child object' do
        expect(page).to have_content('Complete')
      end

      it 'shows the duration of the batch process' do
        expect(page).to have_content('seconds')
      end
    end
  end
end
