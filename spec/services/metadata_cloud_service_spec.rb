# frozen_string_literal: true
require "rails_helper"
require "webmock"

WebMock.allow_net_connect!

RSpec.describe MetadataCloudService, vpn_only: true do
  let(:mcs) { described_class.new }

  it "can connect to the metadata cloud using basic auth" do
    expect(mcs.mc_get.to_str).to include "Manuscript, on parchment"
  end

  it "can read from a csv file" do
    expect(mcs.oid_array).to include "2034600"
  end

  it "can loop through the oids and build a metadata cloud default url" do
    expect(mcs.build_metadata_cloud_url).to include "https://metadata-api-test.library.yale.edu/metadatacloud/api/ladybird/oid/16371272?mediaType=json"
  end

end
