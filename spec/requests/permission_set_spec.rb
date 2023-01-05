# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Permission Sets', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }

  before do
    login_as user
  end

  let(:valid_attributes) do
    {
      key: "New Key",
      label: "New Label"
    }
  end

  let(:updated_attributes) do
    {
      key: "New Key",
      label: "New Label"
    }
  end

  describe 'update /permission_sets' do
    context 'with valid attributes' do
      it 'updates permission set' do
        permission_set = PermissionSet.create(valid_attributes)
        patch permission_set_url(permission_set), params: { permission_set: updated_attributes }
        permission_set.reload
        expect(permission_set.key).to eq "New Key"
        expect(response).to have_http_status(:found)
        expect(response).to have_http_status(302)
      end
    end
  end
end
