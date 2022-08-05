# frozen_string_literal: true

require 'rails_helper'

class MockToken
  include JwtWebToken
end

RSpec.describe 'Ranges', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:oid) { 2_034_600 }
  let(:parent) { FactoryBot.create(:parent_object, oid: oid, admin_set: admin_set, visibility: "Public") }
  let(:child) { FactoryBot.create(:child_object, parent_object: parent, oid: 12_345_678) }
  let(:token) { MockToken.new.jwt_encode(user_id: user&.id) }
  let(:headers) { { "Authorization": "Bearer " + token } }

  before do
    stub_metadata_cloud(oid)
    user.add_role(:editor, admin_set)
  end

  describe 'index' do
    context 'with user access' do
      it 'returns a manifest for the parent object' do
        login_as user
        get "/parent_objects/#{parent.oid}/manifest.json"
        expect(response).to have_http_status(:ok)
      end

      it 'returns manifest' do
        get "/parent_objects/#{parent.oid}/manifest.json", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end

    context 'without user access' do
      it 'returns not allowed' do
        user.revoke(:editor, admin_set)
        login_as user
        get "/parent_objects/#{parent.oid}/manifest.json"
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized' do
        user.revoke(:editor, admin_set)
        get "/parent_objects/#{parent.oid}/manifest.json", headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
