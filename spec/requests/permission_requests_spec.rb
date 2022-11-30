# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Permission Requests', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:permission_set) { FactoryBot.create(:permission_set, max_queue_length: 1) }
  let(:oid) { 2_034_600 }
  let(:parent) { FactoryBot.create(:parent_object, oid: oid, admin_set: admin_set, visibility: "Public", permission_set_id: permission_set.id) }
  let(:json) { File.read(Rails.root.join(fixture_path, 'permission_request.json')) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

  before do
    stub_metadata_cloud(oid)
    parent
    login_as user
    user.add_role(:editor, admin_set)
    user.add_role(:approver, permission_set)
  end

  describe 'POST /api/permission_requests' do
    it 'creates a new permission request' do
      request = JSON.parse(json)
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(:created)
      expect(PermissionRequest.all.count).to eq 1
    end

    it 'errors if requests go over max' do
      request = JSON.parse(json)
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(:created)
      expect(PermissionRequest.all.count).to eq 1
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(403)
      expect(PermissionRequest.all.count).to eq 1
    end
  end
end
