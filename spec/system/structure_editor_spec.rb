# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Structure Editor", type: :system, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  before do
    stub_ptiffs_and_manifests
    login_as user
    stub_metadata_cloud("2012036")
  end


# manifest loads in structure editor

# can add range

# can add canvas

# can delete range

# can delete canvas

# can drag canvas

# can submit structure back to management