# frozen_string_literal: true

require 'rails_helper'

WebMock.allow_net_connect!

RSpec.describe IiifManifest do
  let(:oid) { "2107188" }
  let(:manifest) { described_class.new }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }
  before do
    stub_request(:post, "https://yul-development-samples.s3.amazonaws.com/manifests/2107188.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "2107188.json")).read)
  end

  it "can download a manifest from S3" do
    expect(manifest.fetch_manifest(oid)).to include "Fair Lucretia’s garland"
  end

  it "can save a manifest to S3" do
    allow(Rails.logger).to receive(:info) { :logger_mock }
    manifest.save_manifest(oid)
    expect(Rails.logger).to have_received(:info)
      .with("IIIF Manifest Saved: {\"oid\":\"#{oid}\"}")
  end

  it "can generate valid json" do
    expect(manifest.generate_manifest).to
  end
end
