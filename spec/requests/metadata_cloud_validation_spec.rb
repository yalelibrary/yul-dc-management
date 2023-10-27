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

  let(:wrong_version_url) { "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/clearly_fake_version/ladybird/oid/#{oid}?include-children=1" }

  let(:oid) { "16371272" }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '16371272') }
  let(:oid_url) { "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/ladybird/oid/#{oid}?include-children=1" }
  let(:ladybird_source) { FactoryBot.build(:metadata_source) }
  let(:response) { ladybird_source.mc_get(oid_url) }
  let(:no_parent_object_url) { "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/ladybird/oid/1?include-children=1" }
  let(:bad_request_response) { ladybird_source.mc_get(no_parent_object_url) }
  let(:wrong_version_response) { ladybird_source.mc_get(wrong_version_url) }

  let(:sierra_parent_object) { FactoryBot.create(:parent_object, authoritative_metadata_source_id: 4, oid: '12345', bib: '414464') }
  let(:sierra_url) { "https://metadata-api-test.library.yale.edu/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/sierra/bib/#{sierra_parent_object.bib}" }
  let(:sierra_source) { FactoryBot.build(:metadata_source_sierra) }
  let(:sierra_response) { sierra_source.mc_get(sierra_url) }

  it "can connect to the metadata cloud using basic auth" do
    expect(response.status.success?).to be true
    expect(response.body.to_str).to include "Manuscript, on parchment"
    expect(response.body.to_str).to include "/ladybird/oid/16565592"
    expect(response.content_type).to include "application/json"
  end

  it "can connect to the sierra metadata cloud using basic auth" do
    expect(sierra_response.status.success?).to be true
    expect(sierra_response.body.to_str).to include "/sierra/bib/414464"
    expect(sierra_response.content_type).to include "application/json"
  end

  it "has the expected fields" do
    data = JSON.parse(response.body.to_s)
    expect(data.keys.sort).to eq ["jsonModelType", "source", "callNumber", "title", "extentOfDigitization", "creationPlace",
                                  "date", "extent", "language", "description", "subjectName", "subjectTopic", "genre",
                                  "format", "itemType", "partOf", "rights", "orbisBibId", "orbisBarcode",
                                  "preferredCitation", "itemPermission", "dateStructured", "illustrativeMatter",
                                  "intStartYear", "intEndYear", "subjectEra", "contributor", "repository", "subjectTitle",
                                  "subjectTitleDisplay", "contributorDisplay", "dependentUris", "oid", "collectionId",
                                  "children", "abstract", "uri", "recordType"].sort
  end

  # rubocop:disable Metrics/LineLength
  it "has the expected sierra fields" do
    data = JSON.parse(sierra_response.body.to_s)
    expect(data.keys.sort).to eq ["bibId", "callNumber", "children", "creationPlace", "creator", "creatorDisplay", "date",
                                  "dateStructured", "dependentUris", "description", "extent", "illustrativeMatter", "itemType", "jsonModelType", "language", "languageCode", "libraryOfCongressClassificationNumber", "orbisBibId", "publisher", "recordType", "source", "subjectHeading", "subjectTopic", "title", "titleStatement", "uri"].sort
  end
  # rubocop:enable Metrics/LineLength

  it "gets a successful response from the Metadata Cloud" do
    expect(ladybird_source.fetch_record_on_vpn(parent_object)).to include "Manuscript, on parchment, of the books of the Bible from Proverbs through"
  end

  it "gets a successful response from the Sierra Metadata Cloud" do
    expect(sierra_source.fetch_record_on_vpn(sierra_parent_object)).to include "Das verbrecherische verhalten des geisteskranken"
  end

  it "gets a 'bad request' when asking for a non-existent parent_object oid" do
    expect(bad_request_response.status.success?).to be false
    expect(bad_request_response.status).to eq 400
    expect(JSON.parse(bad_request_response.body)["ex"]).to include "Record not found"
  end

  it "gets a 'Unable to find retriever for source' when the wrong version is set" do
    expect(wrong_version_response.status.success?).to be false
    expect(wrong_version_response.status).to eq 400
    expect(JSON.parse(wrong_version_response.body)["ex"]).to include "Unable to find retriever for source"
  end
end
