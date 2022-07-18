# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Ranges', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:oid) { 2_034_600 }
  let(:parent) { FactoryBot.create(:parent_object, oid: oid, source_name: 'ladybird', visibility: "Public") }
  let(:child) { FactoryBot.create(:child_object, parent_object: parent, oid: 12_345_678) }
  before do
    stub_metadata_cloud(oid)
    login_as user
  end

  describe 'POST /range' do
    it 'parses a Manifest' do
      rb = IiifRangeBuilder.new
      json = File.read(Rails.root.join(fixture_path, 'v3_spec_range1.json'))
      json = format(json, parent_id: parent.oid, child_id: child.oid)
      range = JSON.parse(json)
      headers = { 'CONTENT_TYPE' => 'application/json' }
      post "/parent_objects/#{parent.oid}/range", params: JSON.pretty_generate(range), headers: headers
      id = rb.uuid_from_uri(range['id'])
      expect(response).to redirect_to("/range/#{id}")
      expect(response).to have_http_status(:found)
    end
  end

  describe 'PUT /range' do
    it 'updates  a Manifest' do
      rb = IiifRangeBuilder.new
      json = File.read(Rails.root.join(fixture_path, 'v3_spec_range1.json'))
      json = format(json, parent_id: parent.oid, child_id: child.oid)
      manifest = JSON.parse(json)
      range = rb.parse_range(parent, manifest, 1)
      headers = { 'CONTENT_TYPE' => 'application/json' }
      put "/parent_objects/#{parent.oid}/range/#{range.resource_id}", params: JSON.pretty_generate(manifest), headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'updates a Manifest' do
      rb = IiifRangeBuilder.new
      json = File.read(Rails.root.join(fixture_path, 'v3_spec_range1.json'))
      json = format(json, parent_id: parent.oid, child_id: child.oid)
      manifest = JSON.parse(json)
      id = rb.uuid_from_uri(manifest['id'])
      headers = { 'CONTENT_TYPE' => 'application/json' }
      put "/parent_objects/#{parent.oid}/range/#{id}", params: JSON.pretty_generate(manifest), headers: headers
      expect(response).to have_http_status(:created)
    end
  end
end
