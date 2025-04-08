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
  let(:ladybird_source) { MetadataSource.first }
  let(:response) { ladybird_source.mc_get(oid_url) }
  let(:no_parent_object_url) { "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/ladybird/oid/1?include-children=1" }
  let(:bad_request_response) { ladybird_source.mc_get(no_parent_object_url) }
  let(:wrong_version_response) { ladybird_source.mc_get(wrong_version_url) }

  let(:sierra_parent_object) { FactoryBot.create(:parent_object, authoritative_metadata_source_id: 4, oid: '12345', bib: '414464') }
  let(:sierra_url) { "https://metadata-api-test.library.yale.edu/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/sierra/bib/#{sierra_parent_object.bib}" }
  let(:sierra_source) { FactoryBot.build(:metadata_source_sierra) }
  let(:sierra_response) { sierra_source.mc_get(sierra_url) }
  let(:alma_source) { FactoryBot.build(:metadata_source_alma) }
  let(:alma_parent_object) { FactoryBot.create(:parent_object, oid: '54321', authoritative_metadata_source_id: alma_source.id, alma_item: '2325391950008651') }
  let(:alma_url) { "https://metadata-api-test.library.yale.edu/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/alma/item/#{alma_parent_object.alma_item}" }
  let(:alma_response) { alma_source.mc_get(alma_url) }

  it "can connect to the metadata cloud using basic auth" do
    expect(response.status.success?).to be true
    expect(response.body.to_str).to include "Manuscript, on parchment"
    expect(response.body.to_str).to include "/ladybird/oid/16565592"
    expect(response.content_type.mime_type).to eq "application/json"
  end

  it "can connect to the sierra metadata cloud using basic auth" do
    expect(sierra_response.status.success?).to be true
    expect(sierra_response.body.to_str).to include "/sierra/bib/414464"
    expect(sierra_response.content_type.mime_type).to eq "application/json"
  end

  it "can connect to the alma metadata cloud using basic auth" do
    byebug
    expect(alma_response.status.success?).to be true
    expect(alma_response.body.to_str).to include "/alma/item/2325391950008651"
    expect(alma_response.content_type.mime_type).to eq "application/json"
  end

  # rubocop:disable Layout/LineLength
  it "has the expected fields" do
    data = JSON.parse(response.body.to_s)
    expect(data.keys.sort).to eq ["abstract", "callNumber", "children", "collectionId", "contributor", "contributorDisplay", "creationPlace", "date", "dateStructured", "dependentUris", "description", "extent", "extentOfDigitization", "format", "genre", "illustrativeMatter", "intEndYear", "intStartYear", "itemPermission", "itemType", "jsonModelType", "language", "oid", "orbisBarcode", "orbisBibId", "partOf", "preferredCitation", "projectId", "recordType", "repository", "rights", "source", "subjectEra", "subjectName", "subjectTitle", "subjectTitleDisplay", "subjectTopic", "title", "uri"]
  end

  it "has the expected sierra fields" do
    data = JSON.parse(sierra_response.body.to_s)
    expect(data.keys.sort).to eq ["bibId", "children", "creationPlace", "creator", "creatorDisplay", "date", "dateStructured", "dependentUris", "description", "extent", "illustrativeMatter", "itemType", "jsonModelType", "language", "languageCode", "libraryOfCongressClassificationNumber", "orbisBibId", "publisher", "recordType", "source", "subjectHeading", "subjectTopic", "title", "titleStatement", "uri"]
  end
  # rubocop:enable Layout/LineLength

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
