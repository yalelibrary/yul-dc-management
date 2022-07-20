# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Ranges', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:rb) { IiifRangeBuilder.new }
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:oid) { 2_034_600 }
  let(:parent) { FactoryBot.create(:parent_object, oid: oid, source_name: 'ladybird', visibility: "Public") }
  let(:child) { FactoryBot.create(:child_object, parent_object: parent, oid: 12_345_678) }
  let(:json) { File.read(Rails.root.join(fixture_path, 'v3_spec_range1.json')) }
  let(:formatted_json) { format(json, parent_id: parent.oid, child_id: child.oid) }
  let(:manifest) { JSON.parse(formatted_json) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

  before do
    stub_metadata_cloud(oid)
    login_as user
  end

  describe 'GET /range' do
    it 'returns a manifest' do
      range = rb.parse_range(parent, manifest, 1)
      get "/parent_objects/#{parent.oid}/range/#{range.resource_id}", params: JSON.pretty_generate(manifest), headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /range' do
    it 'parses a Manifest' do
      range = JSON.parse(formatted_json)
      post "/parent_objects/#{parent.oid}/range", params: JSON.pretty_generate(range), headers: headers
      id = rb.uuid_from_uri(range['id'])
      expect(response).to redirect_to("/range/#{id}")
      expect(response).to have_http_status(:found)
    end
  end

  describe 'PUT /range' do
    it 'updates a Manifest with resource id' do
      range = rb.parse_range(parent, manifest, 1)
      put "/parent_objects/#{parent.oid}/range/#{range.resource_id}", params: JSON.pretty_generate(manifest), headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'updates a Manifest with range id' do
      id = rb.uuid_from_uri(manifest['id'])
      put "/parent_objects/#{parent.oid}/range/#{id}", params: JSON.pretty_generate(manifest), headers: headers
      expect(response).to have_http_status(:created)
    end
  end

  describe 'DELETE /range' do
    it 'deletes a manifest' do
      id = rb.uuid_from_uri(manifest['id'])
      delete "/parent_objects/#{parent.oid}/range/#{id}", params: JSON.pretty_generate(manifest), headers: headers
      expect(response).to have_http_status(:redirect)
    end
  end
end
