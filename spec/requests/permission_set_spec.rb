# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Permission Sets', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:valid_attributes) do
    {
      key: "New Key",
      label: "New Label"
    }
  end

  let(:invalid_attributes) do
    {
      key: "",
      label: "Label"
    }
  end

  let(:updated_attributes) do
    {
      key: "Newer Key",
      label: "Newer Label"
    }
  end
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:permission_set) { FactoryBot.create(:permission_set, label: 'set 1') }
  let(:request_user) { FactoryBot.create(:permission_request_user) }
  let(:permission_set_2) { FactoryBot.create(:permission_set, label: 'set 2') }
  let(:permission_set_3) { FactoryBot.create(:permission_set, label: 'set 3') }
  let(:terms) { FactoryBot.create(:permission_set_term, activated_at: Time.zone.now, permission_set_id: permission_set.id) }
  let(:terms_2) { FactoryBot.create(:permission_set_term, inactivated_at: Time.zone.now, permission_set_id: permission_set_3.id) }

  before do
    permission_set
    permission_set_2
    permission_set_3
    request_user
    terms
    terms_2
  end

  describe 'update /permission_sets' do
    before do
      login_as user
    end
    it 'updates permission set with valid attributes' do
      permission_set = PermissionSet.create! valid_attributes
      patch permission_set_url(permission_set), params: { permission_set: updated_attributes }
      permission_set.reload
      expect(permission_set.key).to eq "Newer Key"
      expect(response).to have_http_status(302)
    end

    it 'does not update permission set with invalid attributes' do
      permission_set = PermissionSet.create(valid_attributes)
      patch permission_set_url(permission_set), params: { permission_set: invalid_attributes }
      permission_set.reload
      expect(permission_set.key).to eq "New Key"
      expect(response).to have_http_status(200)
    end
  end

  describe 'get /api/permission_sets/id/terms' do
    before do
      login_as user
    end
    it 'can display the active permission set term' do
      get terms_api_path(permission_set)
      expect(response).to have_http_status(200)
      expect(response.body).to match("[{\"id\":3,\"title\":\"Permission Set Terms\",\"body\":\"These are some terms\"}]")
    end
    it 'can display terms not found' do
      get terms_api_path(permission_set_2)
      expect(response).to have_http_status(204)
    end
    it 'displays permission set not found' do
      get terms_api_path(12)
      expect(response).to have_http_status(400)
      expect(response.body).to eq("{\"title\":\"Permission Set not found\"}")
    end
    it 'displays permission set without an active term and condition' do
      get terms_api_path(permission_set_3)
      expect(response).to have_http_status(204)
    end
  end

  describe 'GET /api/permission_sets/id/permission_set_terms/id/agree/sub' do
    it 'can GET and create a user agreement' do
      expect(TermsAgreement.count).to eq 0
      get "/api/permission_sets/#{permission_set.id}/permission_set_terms/#{terms.id}/agree/#{request_user.sub}"
      expect(response).to have_http_status(201)
      term = TermsAgreement.first
      expect(TermsAgreement.count).to eq 1
      expect(term.permission_request_user).to eq request_user
      expect(term.permission_set_term).to eq terms
    end
    it 'throws error if user not found' do
      get "/api/permission_sets/#{permission_set.id}/permission_set_terms/#{terms.id}/agree/123"
      expect(response).to have_http_status(400)
      expect(response.body).to eq("{\"title\":\"User not found.\"}")
    end
    it 'throws error if permission set term not found' do
      get "/api/permission_sets/#{permission_set.id}/permission_set_terms/123/agree/#{request_user.sub}"
      expect(response).to have_http_status(400)
      expect(response.body).to eq("{\"title\":\"Term not found.\"}")
    end
  end

  describe 'get /api/permission_sets/id/terms' do
    it "a non-user can access the permission set terms" do
      get terms_api_path(permission_set)
      expect(response).to have_http_status(200)
      expect(response.body).to match("[{\"id\":3,\"title\":\"Permission Set Terms\",\"body\":\"These are some terms\"}]")
    end
  end
end
