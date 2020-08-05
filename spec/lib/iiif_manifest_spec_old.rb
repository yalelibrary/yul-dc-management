# frozen_string_literal: true

require 'rails_helper'

WebMock.allow_net_connect!

RSpec.describe IiifManifest, prep_metadata_sources: true do
  let(:oid) { "2107188" }
  let(:iiif_manifest) { described_class.new }
  let(:lucretia_manifest) { described_class.generate_manifest(oid) }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }
  before do
    stub_request(:post, "https://yul-development-samples.s3.amazonaws.com/manifests/2107188.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "2107188.json")).read)
  end

  it "can download a manifest from S3" do
    expect(iiif_manifest.fetch_manifest(oid)).to include "Fair Lucretia’s garland"
  end

  it "can save a manifest to S3" do
    allow(Rails.logger).to receive(:info) { :logger_mock }
    iiif_manifest.save_manifest(oid)
    expect(Rails.logger).to have_received(:info)
      .with("IIIF Manifest Saved: {\"oid\":\"#{oid}\"}")
  end

  it "can generate valid json" do
    expect(JsonValidator.valid?(described_class.generate_manifest(oid))).to be true
  end

  it "has the correct identifier" do
    expect(lucretia_manifest["@id"]).to eq "http://localhost/manifests/2107188.json"
  end

  it "labels the manifest with the title of the ParentObject" do
    expect(lucretia_manifest["label"]).to eq "Fair Lucretia’s garland"
  end
end
