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
  # let(:parent_object) do
  #   FactoryBot.create(
  #     :parent_object,
  #     oid: '16057779'
  #   )
  # end
  let(:child_object) do
    FactoryBot.create(
      :child_object,
      parent_object: :parent_object
    )
  end

  before do
    login_as user
  end

  around do |example|
    vpn = ENV['VPN']
    ENV['VPN'] = 'false'
    example.run
    ENV['VPN'] = vpn
  end

  describe 'with expected success' do
    before do
      # stub_metadata_cloud('2004628')
      # stub_metadata_cloud('2030006')
      # stub_metadata_cloud('2034600')
      # stub_metadata_cloud('16057779')
      # stub_metadata_cloud('15234629')
      # stub_ptiffs_and_manifests
    end

    describe 'with a csv import' do
      it 'has a link to the batch process detail page' do
        byebug
        visit show_child_batch_process_path(child_object, batch_process, batch_process.parent_objects.first.oid)
        expect(page).to have_link(batch_process&.id&.to_s, href: "/batch_processes/#{batch_process.id}")
      end

      it 'has a link to the parent object page' do
        visit show_child_batch_process_path(batch_process, 16_057_779)
        expect(page).to have_link('16057779 (current record)', href: '/parent_objects/16057779')
      end

      it 'shows the status of the child object' do
        visit show_child_batch_process_path(batch_process, 16_057_779)
        expect(page).to have_content('In progress - no failures')
      end

      it 'shows the duration of the batch process' do
        visit show_child_batch_process_path(batch_process, 16_057_779)
        expect(page).to have_content('2020-10-08 14:17:01 UTC')
      end
    end
  end
end
