# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Permission Requests API', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:approver_user_one) { FactoryBot.create(:user) }
  let(:approver_user_two) { FactoryBot.create(:user) }
  let(:admin_user) { FactoryBot.create(:user) }
  let(:sysadmin_user) { FactoryBot.create(:sysadmin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:permission_set) { FactoryBot.create(:permission_set, max_queue_length: 1) }
  let(:permission_set_two) { FactoryBot.create(:permission_set, key: 'abc', label: 'Secondary') }
  let(:oid) { 2_034_600 }
  let(:oid_two) { "17105661" }
  let(:oid_three) { "30000016189097" }
  let(:parent) { FactoryBot.create(:parent_object, oid: oid, admin_set: admin_set, visibility: "Open with Permission", permission_set_id: permission_set.id) }
  let(:parent_two) { FactoryBot.create(:parent_object, oid: oid_two, admin_set: admin_set, visibility: "Public", permission_set_id: permission_set.id) }
  let(:parent_three) { FactoryBot.create(:parent_object, oid: oid_three, admin_set: admin_set, visibility: "Private", permission_set_id: permission_set.id) }
  let(:json) { File.read(Rails.root.join(fixture_path, 'permission_request.json')) }
  let(:invalid_oid_json) { File.read(Rails.root.join(fixture_path, 'invalid_oid_permission_request.json')) }
  let(:public_visibility_json) { File.read(Rails.root.join(fixture_path, 'public_visibility_permission_request.json')) }
  let(:private_visibility_json) { File.read(Rails.root.join(fixture_path, 'private_visibility_permission_request.json')) }
  let(:invalid_sub_json) { File.read(Rails.root.join(fixture_path, 'invalid_sub_permission_request.json')) }
  let(:invalid_name_json) { File.read(Rails.root.join(fixture_path, 'invalid_name_permission_request.json')) }
  let(:invalid_email_json) { File.read(Rails.root.join(fixture_path, 'invalid_email_permission_request.json')) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

  before do
    stub_metadata_cloud(oid)
    stub_metadata_cloud(oid_two)
    stub_metadata_cloud(oid_three)
    parent
    parent_two
    parent_three
    sysadmin_user
    approver_user_one.add_role(:editor, admin_set)
    approver_user_two.add_role(:editor, admin_set)
    admin_user.add_role(:editor, admin_set)
    approver_user_one.add_role(:approver, permission_set)
    approver_user_two.add_role(:approver, permission_set)
    admin_user.add_role(:administrator, permission_set)
    login_as approver_user_one
  end

  describe '/api/permission_requests' do
    it 'creates a new permission request and sends emails to approvers and admins but not sysadmins' do
      request = JSON.parse(json)
      expect do
        post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      end.to change { ActionMailer::Base.deliveries.count }.by(3)
      expect(ActionMailer::Base.deliveries[0].to).to eq [approver_user_one.email]
      expect(ActionMailer::Base.deliveries[1].to).to eq [approver_user_two.email]
      expect(ActionMailer::Base.deliveries[2].to).to eq [admin_user.email]
      expect(ActionMailer::Base.deliveries.each(&:to)).not_to eq [sysadmin_user.email]
      expect(response).to have_http_status(:created)
      expect(OpenWithPermission::PermissionRequest.all.count).to eq 1
      pr = OpenWithPermission::PermissionRequest.first
      expect(pr.user_note).not_to be nil
    end

    it 'errors if requests go over max' do
      request = JSON.parse(json)
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(:created)
      expect(OpenWithPermission::PermissionRequest.all.count).to eq 1
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(403)
      expect(OpenWithPermission::PermissionRequest.all.count).to eq 1
    end

    it 'errors if a parent OID is invalid' do
      request = JSON.parse(invalid_oid_json)
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(400)
      expect(response.body).to match("{\"title\":\"Invalid Parent OID\"}")
    end

    it 'errors if a users subject is missing' do
      request = JSON.parse(invalid_sub_json)
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(400)
      expect(response.body).to match("{\"title\":\"User subject is missing\"}")
    end

    it 'errors if a users name is missing' do
      request = JSON.parse(invalid_name_json)
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(400)
      expect(response.body).to match("{\"title\":\"User name is missing\"}")
    end

    it 'errors if a users email is missing' do
      request = JSON.parse(invalid_email_json)
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(400)
      expect(response.body).to match("{\"title\":\"User email is missing\"}")
    end

    it 'errors if a parent object visibility is public' do
      request = JSON.parse(public_visibility_json)
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(400)
      expect(response.body).to match("{\"title\":\"Parent Object is public, permission not required\"}")
    end

    it 'errors if a parent object visibility is private' do
      request = JSON.parse(private_visibility_json)
      post "/api/permission_requests", params: JSON.pretty_generate(request), headers: headers
      expect(response).to have_http_status(400)
      expect(response.body).to match("{\"title\":\"Parent Object is private\"}")
    end
  end
end
