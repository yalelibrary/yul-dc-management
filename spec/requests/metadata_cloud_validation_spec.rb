# frozen_string_literal: true

require 'rails_helper'

WebMock.allow_net_connect!

RSpec.describe "MetadataCloud validation", type: :request, prep_metadata_sources: true, vpn_only: true do
  around do |example|
    original_vpn = ENV['VPN']
    original_metadata_cloud_host = ENV['METADATA_CLOUD_HOST']
    ENV['METADATA_CLOUD_HOST'] = "metadata-api.library.yale.edu"
    ENV['VPN'] = 'true'
    example.run
    ENV['VPN'] = original_vpn
    ENV['METADATA_CLOUD_HOST'] = original_metadata_cloud_host
  end

  let(:oid) { "16371272" }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '16371272') }
  let(:oid_url) { "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/ladybird/oid/#{oid}?include-children=1" }
  let(:ladybird_source) { FactoryBot.build(:metadata_source) }
  let(:response) { ladybird_source.mc_get(oid_url) }
  let(:no_parent_object_url) { "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/ladybird/oid/1?include-children=1" }
  let(:bad_request_response) { ladybird_source.mc_get(no_parent_object_url) }

  it "can connect to the metadata cloud using basic auth" do
    expect(response.status.success?).to be true
    expect(response.body.to_str).to include "Manuscript, on parchment"
    expect(response.body.to_str).to include "/ladybird/oid/16565592"
    expect(response.content_type).to include "application/json"
  end

  it "has the expected fields" do
    data = JSON.parse(response.body.to_s)
    expect(data.keys).to eq ["jsonModelType", "source", "recordType", "uri", "identifierShelfMark", "title",
                             "extentOfDigitization", "publicationPlace", "date", "extent", "language",
                             "description", "subjectName", "subjectTopic", "genre", "format", "partOf",
                             "rights", "orbisRecord", "orbisBarcode", "references", "itemPermission",
                             "dateStructured", "resourceType", "illustrativeMatter", "subjectEra", "contributor",
                             "repository", "contents", "subjectTitle", "indexedBy", "subjectTitleDisplay",
                             "contributorDisplay", "dependentUris", "oid", "collectionId", "children", "abstract"]
  end

  it "gets a successful response from the Metadata Cloud" do
    expect(ladybird_source.fetch_record_on_vpn(parent_object)).to include "Manuscript, on parchment, of the books of the Bible from Proverbs through"
  end

  it "gets a 'bad request' when asking for a non-existent parent_object oid" do
    expect(bad_request_response.status.success?).to be false
    expect(bad_request_response.status).to eq 400
  end
end
