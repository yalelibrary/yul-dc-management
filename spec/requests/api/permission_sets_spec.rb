# frozen_string_literal: true
require 'rails_helper'

RSpec.describe '/api/permission_sets/po/terms', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:permission_set) { FactoryBot.create(:permission_set, label: 'set 1') }
  let(:permission_set_2) { FactoryBot.create(:permission_set, label: 'set 2') }
  let(:permission_set_3) { FactoryBot.create(:permission_set, label: 'set 3') }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 2_012_036, admin_set: AdminSet.find_by_key('brbl'), permission_set: permission_set, visibility: "Open with Permission") }
  let(:parent_object_no_ps) { FactoryBot.create(:parent_object, oid: 2_012_033, admin_set: AdminSet.find_by_key('brbl')) }
  let(:parent_object_no_terms) { FactoryBot.create(:parent_object, oid: 2_012_037, admin_set: AdminSet.find_by_key('brbl'), permission_set: permission_set_2, visibility: "Open with Permission") }
  let(:request) { FactoryBot.create(:permission_request, permission_request_user: request_user, permission_set: permission_set, parent_object: parent_object) }
  let(:term_agreement) { FactoryBot.create(:term_agreement, permission_request_user: request_user, permission_set_term: terms) }
  let(:terms) { FactoryBot.create(:permission_set_term, activated_by: user, activated_at: Time.zone.now, permission_set: permission_set) }
  let(:request_user) { FactoryBot.create(:permission_request_user, sub: '1234') }
  let(:params) do
    {
      'oid': '123',
      'user_email': 'email',
      'user_netid': 'netid',
      'user_sub': 'sub',
      'user_full_name': "new",
      'permission_set_terms_id': terms.id
    }
  end
  let(:invalid_term_params) do
    {
      'oid': '123',
      'user_email': 'email',
      'user_netid': 'netid',
      'user_sub': 'sub',
      'user_full_name': "new",
      'permission_set_terms_id': '1'
    }
  end
  let(:invalid_user_params) do
    {
      'oid': '123',
      'user_email': 'email',
      'user_full_name': "new",
      'permission_set_terms_id': terms.id
    }
  end

  before do
    login_as user
    parent_object
    parent_object_no_ps
    permission_set
    permission_set_2
    permission_set_3
    request_user
    terms
    request
    term_agreement
  end

  describe 'get /api/permission_sets/id/terms' do
    it 'can display the active permission set term' do
      get terms_api_path(parent_object)
      expect(response).to have_http_status(200)
      expect(response.body).to match("[{\"id\":3,\"title\":\"Permission Set Terms\",\"body\":\"These are some terms\"}]")
    end
    it 'can display terms not found' do
      get terms_api_path(parent_object_no_terms)
      expect(response).to have_http_status(204)
    end
    it 'displays parent object not found' do
      get terms_api_path(9_765_431)
      expect(response).to have_http_status(400)
      expect(response.body).to eq("{\"title\":\"Parent Object not found\"}")
    end
    it 'displays permission set not found' do
      get terms_api_path(2_012_033)
      expect(response).to have_http_status(400)
      expect(response.body).to eq("{\"title\":\"Permission Set not found\"}")
    end
  end

  describe 'POST /agreement_term' do
    it 'can POST and create a user agreement' do
      expect(OpenWithPermission::TermsAgreement.count).to eq 1
      post agreement_term_url(params)
      expect(response).to have_http_status(201)
      term = OpenWithPermission::TermsAgreement.first
      expect(OpenWithPermission::TermsAgreement.count).to eq 2
      expect(term.permission_request_user).to eq request_user
      expect(term.permission_set_term).to eq terms
    end
    it 'throws error if user not found' do
      post agreement_term_url(invalid_user_params)
      expect(response).to have_http_status(400)
      expect(response.body).to eq("{\"title\":\"User not found.\"}")
    end
    it 'throws error if permission set term not found' do
      post agreement_term_url(invalid_term_params)
      expect(response).to have_http_status(400)
      expect(response.body).to eq("{\"title\":\"Term not found.\"}")
    end
  end

  describe 'get /api/permission_sets/id/terms' do
    it "a non-user can access the permission set terms" do
      get terms_api_path(parent_object)
      expect(response).to have_http_status(200)
      expect(response.body).to match("[{\"id\":3,\"title\":\"Permission Set Terms\",\"body\":\"These are some terms\"}]")
    end
  end

  # rubocop:disable Metrics/LineLength
  describe 'get /api/permission_sets/:sub' do
    it "can find a user from sub" do
      get '/api/permission_sets/1234'
      expect(response).to have_http_status(200)
      expect(response.body).to match("[{\"user\":{\"sub\":\"#{request_user.sub}\"},\"permission_set_terms_agreed\":[#{term_agreement.id}],\"permissions\":[{\"oid\":2012036,\"permission_set\":#{permission_set.id},\"permission_set_terms\":#{terms.id},\"request_status\":null}]}]")
    end
    it "throws error if user is not found" do
      get '/api/permission_sets/123456'
      expect(response).to have_http_status(404)
      expect(response.body).to eq("{\"title\":\"User not found\"}")
    end
  end
  # rubocop:enable Metrics/LineLength
end
