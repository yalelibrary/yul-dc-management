# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'ParentObjects', type: :system, prep_metadata_sources: true, prep_admin_sets: true, skip_db_cleaner: true do
  context 'parent objects datatable page', js: true do
    let(:user) { FactoryBot.create(:user) }
    let(:admin_set) { FactoryBot.create(:admin_set, key: 'adminset') }
    let(:parent_object1) { FactoryBot.create(:parent_object, oid: '2012036', admin_set_id: admin_set.id, authoritative_metadata_source_id: 3, aspace_uri: '/repositories/11/archival_objects/214639') }
    let(:parent_object2) { FactoryBot.create(:parent_object, oid: '16797069', admin_set_id: admin_set.id, authoritative_metadata_source_id: 3, aspace_uri: '/repositories/11/archival_objects/214636') }

    before do
      stub_metadata_cloud('AS-2012036', 'aspace')
      stub_metadata_cloud('AS-16797069', 'aspace')
      parent_object1
      parent_object2
      user.add_role(:editor, admin_set)
      login_as user
    end

    it 'displays parent objects without filter' do
      visit parent_objects_path
      expect(page).to have_content('2012036')
      expect(page).to have_content('16797069')
      # filters when filter box is filled
      find("input[placeholder='OID']").set('2012')
      expect(page).to have_content('2012036')
      expect(page).not_to have_content('16797069')
      # retains filters and fills filter boxes on refresh
      find("input[placeholder='OID']").set('2012')
      expect(page).to have_content('2012036')
      expect(page).not_to have_content('16797069')
      visit current_path
      expect(page).to have_content('2012036')
      expect(page).not_to have_content('16797069')
      expect(find("input[placeholder='OID']").value).to eq('2012')
      # clears filter when Clear Filters is clicked' do
      visit parent_objects_path
      find("input[placeholder='OID']").set('2012')
      expect(page).to have_content('2012036')
      expect(page).not_to have_content('16797069')
      click_on('Clear Filters')
      expect(page).to have_content('2012036')
      expect(page).to have_content('16797069')
    end
  end
end
