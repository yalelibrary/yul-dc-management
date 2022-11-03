# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Structure Editor", type: :system, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  # parent object has two child objects
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2012036", admin_set_id: admin_set.id) }
  
  before do
    stub_ptiffs_and_manifests
    user.add_role(:editor, admin_set)
    login_as user
    parent_object
    stub_metadata_cloud("2012036")
  end

  describe 'can access the structure editor' do
    it 'can visit the homepage' do
      visit "/management/parent_objects/#{parent_object.oid}/edit"
      expect(page).to have_content("Manifest Structure")
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