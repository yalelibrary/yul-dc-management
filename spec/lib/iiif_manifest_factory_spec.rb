# frozen_string_literal: true

require 'rails_helper'

WebMock.allow_net_connect!

RSpec.describe IiifManifestFactory, prep_metadata_sources: true do
  let(:oid) { "2107188" }
  let(:manifest_factory) { IiifManifestFactory.new(oid) }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }
  before do
    stub_request(:post, "https://yul-development-samples.s3.amazonaws.com/manifests/2107188.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "2107188.json")).read)
  end

  it "can be instantiated" do
    expect(manifest_factory.oid).to eq oid
  end

  it "has a seed from which to build the manifest" do
    expect(manifest_factory.seed).to be_instance_of Hash
  end

  it "has a manifest with the relevant identifier" do
    expect(manifest_factory.manifest.class).to eq IIIF::Presentation::Manifest
    expect(manifest_factory.manifest["@id"]).to eq "http://localhost/manifests/2107188.json"
  end

end
