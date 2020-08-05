# frozen_string_literal: true

require 'rails_helper'

WebMock.allow_net_connect!

RSpec.describe IiifManifestFactory, prep_metadata_sources: true do
  let(:oid) { "2107188" }
  let(:manifest_factory) { IiifManifestFactory.new(oid) }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: oid) }
  before do
    stub_request(:post, "https://yul-development-samples.s3.amazonaws.com/manifests/2107188.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "2107188.json")).read)
    parent_object
  end

  it "can be instantiated" do
    expect(manifest_factory.oid).to eq oid
  end

  it "has a seed from which to build the manifest" do
    expect(manifest_factory.seed).to be_instance_of Hash
  end

  it "has a manifest" do
    expect(manifest_factory.manifest.class).to eq IIIF::Presentation::Manifest
  end

  it "has a parent object" do
    expect(manifest_factory.parent_object.class).to eq ParentObject
  end

  # see also https://github.com/yalelibrary/yul-dc-iiif-manifest/blob/3f96a09d9d5a7b6a49c051d663b5cc2aa5fd8475/templates/webapp.conf.template#L56
  it "has 127.0.0.1 as the host in the identifier so that hostname substitution works" do
    expect(manifest_factory.manifest["@id"]).to eq "http://127.0.0.1/manifests/2107188.json"
  end

  it "has a label with the title of the ParentObject" do
    expect(manifest_factory.manifest["label"]).to eq "Fair Lucretia’s garland"
  end

  it "can download a manifest from S3" do
    expect(JSON.parse(manifest_factory.fetch_manifest)["label"]).to eq "Fair Lucretia’s garland"
  end

  it "can save a manifest to S3" do
    allow(Rails.logger).to receive(:info) { :logger_mock }
    manifest_factory.save_manifest
    expect(Rails.logger).to have_received(:info)
      .with("IIIF Manifest Saved: {\"oid\":\"#{oid}\"}")
  end
end
