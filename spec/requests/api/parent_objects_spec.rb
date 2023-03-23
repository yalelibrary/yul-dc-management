# frozen_string_literal: true
require 'rails_helper'

RSpec.describe '/api/parent/oid', type: :request, prep_metadata_sources: true, prep_admin_sets: true do
  let(:valid_attributes) do
    {
      oid: '2004628',
      authoritative_metadata_source_id: 1,
      admin_set: AdminSet.find_by_key('brbl'),
      bib: '123',
      visibility: 'Public',
      ladybird_json: {
        oid: '12345',
        uri: '/uri_example'
      }
    }
  end
  let(:invalid_visibility) do
    {
      oid: '2000000',
      authoritative_metadata_source_id: 1,
      admin_set: AdminSet.find_by_key('brbl'),
      bib: '123',
      visibility: 'Private'
    }
  end
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: 123, admin_set: admin_set, visibility: "Public") }
  let(:child_object) { FactoryBot.create(:child_object, oid: 456_789, parent_object: parent_object, caption: 'caption', label: 'label') }

  describe 'GET with valid oid' do
    it 'renders a successful response' do
      ParentObject.create! valid_attributes
      get "/api/parent/#{valid_attributes[:oid]}"
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET with invalid oid' do
    it 'renders a 404 response' do
      get '/api/parent/12345'
      expect(response).to have_http_status(404)
      expect(response.body).to eq("{\"title\":\"Invalid Parent OID\"}")
    end
  end

  describe 'GET with invalid visibility' do
    it 'renders a 403 response' do
      ParentObject.create! invalid_visibility
      get "/api/parent/#{invalid_visibility[:oid]}"
      expect(response).to have_http_status(403)
      expect(response.body).to eq("{\"title\":\"Parent Object is restricted.\"}")
    end
  end

  # rubocop:disable Metrics/LineLength
  describe 'GET metadata from parent object' do
    it 'displays objects metadata' do
      ParentObject.create! valid_attributes
      get "/api/parent/#{valid_attributes[:oid]}"
      expect(response.body).to eq("{\"dcs\":{\"oid\":\"2004628\",\"visibility\":\"Public\",\"metadata_source\":\"ils\",\"bib\":\"123\",\"holding\":\"\",\"item\":\"\",\"barcode\":\"\",\"aspace_uri\":\"\",\"admin_set\":\"Beinecke Library\",\"child_object_count\":\"\",\"representative_child_oid\":\"\",\"rights_statement\":\"\",\"extent_of_digitization\":\"\",\"digitization_note\":\"\",\"call_number\":\"\",\"container_grouping\":\"\",\"redirect_to\":\"\",\"iiif_manifest\":\"http://localhost:3000/manifests/2004628\",\"children\":[]},\"metadata\":{\"oid\":\"12345\",\"uri\":\"/uri_example\"}}")
    end

    it 'displays child information' do
      admin_set
      parent_object
      child_object
      get "/api/parent/123"
      expect(response.body).to eq("{\"dcs\":{\"oid\":\"123\",\"visibility\":\"Public\",\"metadata_source\":\"ils\",\"bib\":\"\",\"holding\":\"\",\"item\":\"\",\"barcode\":\"\",\"aspace_uri\":\"\",\"admin_set\":\"MyString\",\"child_object_count\":\"\",\"representative_child_oid\":\"\",\"rights_statement\":\"\",\"extent_of_digitization\":\"\",\"digitization_note\":\"\",\"call_number\":\"\",\"container_grouping\":\"\",\"redirect_to\":\"\",\"iiif_manifest\":\"http://localhost:3000/manifests/123\",\"children\":[{\"oid\":456789,\"label\":\"label\",\"caption\":\"caption\"}]},\"metadata\":null}")
    end
  end
  # rubocop:enable Metrics/LineLength
end
