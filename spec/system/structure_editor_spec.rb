# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Structure Editor", type: :system, prep_metadata_sources: true, prep_admin_sets: true, js: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has two child objects
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '2012036', admin_set_id: admin_set.id) }
  let(:child_object) { FactoryBot.create(:child_object, oid: '1234567', parent_object: parent_object, caption: 'bola') }

  before do
    stub_ptiffs_and_manifests
    user.add_role(:editor, admin_set)
    login_as user
    parent_object
    stub_metadata_cloud("2012036")
  end

  describe 'can access the structure editor' do
    it 'can visit the homepage' do
      visit "/parent_objects/#{parent_object.oid}/edit"
      expect(page).to have_content('Manifest Structure')
      click_on 'Manifest Structure'
      # new_window = page.window_opened_by do
        # click_on 'Manifest Structure'
      # end
      # new_window = page.driver.browser.window_handles.last
      # page.within_window new_window do
      # session.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
      # page.driver.browser.switch_to_window page.driver.browser.window_handles.last do
      # page.within_window(new_window) do
      #   expect(page).to have_content('Manifest downloaded')
      # end
      # new_window.close
      visit "structure-editor/?manifest=#{root_path}%2Fparent_objects%2F#{parent_object.oid}%2Fmanifest"
      expect(page).to have_content('bola')
    end
  end

end


# manifest loads in structure editor

# can add range

# can add canvas

# can delete range

# can delete canvas

# can drag canvas

# can submit structure back to management