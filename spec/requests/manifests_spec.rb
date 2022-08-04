# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Ranges', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:oid) { 2_034_600 }
  let(:parent) { FactoryBot.create(:parent_object, oid: oid, admin_set: admin_set, visibility: "Public") }
  let(:child) { FactoryBot.create(:child_object, parent_object: parent, oid: 12_345_678) }

  before do
    stub_metadata_cloud(oid)
    login_as user
    user.add_role(:editor, admin_set)
  end

  describe 'index' do
    context 'with user access' do
      it 'returns a manifest for the parent object' do
        get "/parent_objects/#{parent.oid}/manifest.json"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'without user access' do
      it 'returns nothing' do
        user.revoke(:editor, admin_set)
        get "/parent_objects/#{parent.oid}/manifest.json"
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
