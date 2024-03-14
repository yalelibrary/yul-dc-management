# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Permission Requests', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:json) { File.read(Rails.root.join(fixture_path, 'permission_request.json')) }
  let(:admin_set) { AdminSet.first }
  let(:oid) { '2034600' }
  let(:parent_object) { FactoryBot.create(:parent_object, admin_set_id: admin_set.id, oid: oid) }
  let(:permission_set) { FactoryBot.create(:permission_set, key: 'abc', label: 'Secondary') }
  let(:permission_request_user) { FactoryBot.create(:permission_request_user) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

  before do
    stub_metadata_cloud(oid)
    login_as user
  end

  describe 'update' do
    let(:updatable_permission_request) { FactoryBot.create(:permission_request, permission_set: permission_set) }

    context 'with an authenticated approver' do
      it 'will change request status' do
        expect(updatable_permission_request.request_status).to be_nil
        valid_status_update_params = { open_with_permission_permission_request:
          {
            request_status: true,
            change_access_type: 'No'
          } }
        patch "/permission_requests/#{updatable_permission_request.id}", params: JSON.pretty_generate(valid_status_update_params), headers: headers
        expect(response).to have_http_status(302)
        updatable_permission_request.reload
        expect(updatable_permission_request.request_status).to eq true
      end

      it 'will send an email when access type change is requested but does not change visibility of parent object' do
        expect(updatable_permission_request.parent_object.visibility).to eq 'Private'
        valid_access_update_params = { open_with_permission_permission_request:
          {
            new_visibility: 'Public',
            change_access_type: 'Yes'
          } }
        expect do
          patch "/permission_requests/#{updatable_permission_request.id}", params: JSON.pretty_generate(valid_access_update_params), headers: headers
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
        updatable_permission_request.parent_object.reload
        expect(updatable_permission_request.parent_object.visibility).to eq 'Private'
      end

      it 'will change request status (but not the visibility of the parent) and send email' do
        expect(updatable_permission_request.request_status).to be_nil
        expect(updatable_permission_request.parent_object.visibility).to eq 'Private'
        valid_status_and_access_update_params = { open_with_permission_permission_request:
          {
            request_status: true,
            new_visibility: 'Public',
            change_access_type: 'Yes'
          } }
        expect do
          patch "/permission_requests/#{updatable_permission_request.id}", params: JSON.pretty_generate(valid_status_and_access_update_params), headers: headers
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(response).to have_http_status(302)
        updatable_permission_request.reload
        expect(updatable_permission_request.request_status).to eq true
        expect(updatable_permission_request.parent_object.visibility).to eq 'Private'
      end
    end
  end
end
