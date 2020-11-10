# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Batch Process Child detail page', type: :system, prep_metadata_sources: true, js: true do
  let(:user) { FactoryBot.create(:user, uid: 'johnsmith2530') }
  let(:batch_process) do
    FactoryBot.create(
      :batch_process,
      user: user,
      csv: File.open(fixture_path + '/small_short_fixture_ids.csv').read,
      file_name: 'small_short_fixture_ids.csv',
      created_at: '2020-10-08 14:17:01'
    )
  end
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 16_057_779) }
  let(:child_object) { FactoryBot.create(:child_object, parent_object: parent_object) }

  describe 'with expected success' do
    before do
      stub_metadata_cloud('16057779')
      stub_ptiffs_and_manifests
      login_as user
      visit show_child_batch_process_path(child_oid: child_object.oid, id: batch_process.id, oid: child_object.parent_object_oid)
    end

    describe 'with a csv import' do
      it 'has a link to the batch process detail page' do
        expect(page).to have_link(batch_process&.id&.to_s, href: "/batch_processes/#{batch_process.id}")
      end

      it 'has a link to the parent object page' do
        expect(page).to have_link('16057779', href: "/batch_processes/#{batch_process.id}/parent_objects/16057779")
      end

      it 'has a link to the child object page' do
        expect(page).to have_link('10736292 (current record)', href: '/child_objects/10736292')
      end

      it 'shows the status of the child object' do
        expect(page).to have_content('Pending')
      end

      it 'shows the duration of the batch process' do
        expect(page).to have_content('seconds')
      end
    end
  end
end
