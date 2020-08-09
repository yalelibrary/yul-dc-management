# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifManifestFactory, prep_metadata_sources: true do
  let(:oid) { "2012315" }
  let(:path_to_xml) { File.join("spec", "fixtures", "goobi", "metadata", "2012315", "meta.xml") }
  let(:xml_import) { FactoryBot.create(:goobi_xml_import, file: File.open(path_to_xml)) }
  let(:manifest_factory) { IiifManifestFactory.new(oid) }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: oid) }
  let(:first_canvas) { manifest_factory.manifest.sequences.first.canvases.first }
  let(:third_to_last_canvas) { manifest_factory.manifest.sequences.first.canvases.third_to_last }
  before do
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/manifests/2012315.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "2012315.json")).read)
    stub_request(:put, "https://yul-development-samples.s3.amazonaws.com/manifests/2012315.json")
      .to_return(status: 200)
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/ladybird/2012315.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "ladybird", "2012315.json")).read)

    parent_object
    xml_import
  end

  it "has a mets document" do
    expect(manifest_factory.mets_doc.class).to eq MetsDocument
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
    expect(manifest_factory.manifest["@id"]).to eq "http://127.0.0.1/manifests/2012315.json"
  end

  it "has a label with the title of the ParentObject" do
    expect(manifest_factory.manifest["label"]).to eq "Islamic prayers, invocations and decorations : manuscript."
  end

  it "can download a manifest from S3" do
    fetch_manifest = JSON.parse(manifest_factory.fetch_manifest)
    expect(fetch_manifest["label"]).to eq "Islamic prayers, invocations and decorations : manuscript."
  end

  it "has a manifest with one or more sequences" do
    expect(manifest_factory.manifest.sequences.class).to eq Array
  end

  it "has a sequence with an id" do
    expect(manifest_factory.manifest.sequences.first["@id"]).to eq "http://127.0.0.1/manifests/sequence/2012315"
  end

  it "creates a canvas for each file" do
    canvas_count = manifest_factory.manifest.sequences.first.canvases.count
    expect(canvas_count).to eq 10
  end

  it "has a canvases with an ids and labels" do
    expect(first_canvas["@id"]).to eq "http://127.0.0.1/manifests/oid/2012315/canvas/1053442"
    expect(third_to_last_canvas["@id"]).to eq "http://127.0.0.1/manifests/oid/2012315/canvas/1053448"
    expect(first_canvas["label"]).to eq "7v"
    expect(third_to_last_canvas["label"]).to eq "13v"
  end

  it "has a canvas with width and height" do
    expect(first_canvas["height"]).to eq 4075
    expect(first_canvas["width"]).to eq 2630
  end

  it "has canvases with images" do
    expect(first_canvas.images).to be_instance_of Array
    expect(first_canvas.images.count).to eq 1
    expect(first_canvas.images.first["@id"]).to eq "http://127.0.0.1/manifests/oid/2012315/canvas/1053442/image/1"
    expect(first_canvas.images.first["@type"]).to eq "oa:Annotation"
    expect(first_canvas.images.first["motivation"]).to eq "sc:painting"
    expect(first_canvas.images.first["on"]).to eq "http://127.0.0.1/manifests/oid/2012315/canvas/1053442"
    expect(third_to_last_canvas.images.first["@id"]).to eq "http://127.0.0.1/manifests/oid/2012315/canvas/1053448/image/1"
    expect(third_to_last_canvas.images.first["@type"]).to eq "oa:Annotation"
    expect(third_to_last_canvas.images.first["motivation"]).to eq "sc:painting"
    expect(third_to_last_canvas.images.first["on"]).to eq "http://127.0.0.1/manifests/oid/2012315/canvas/1053448"
  end

  it "has an image with a resource" do
    expect(first_canvas.images.first["resource"]["@id"]).to eq "http://iiif_image:8182/iiif/2/1053442/full/!200,200/0/default.jpg"
    expect(third_to_last_canvas.images.first["resource"]["@id"]).to eq "http://iiif_image:8182/iiif/2/1053448/full/!200,200/0/default.jpg"
    expect(first_canvas.images.first["resource"]["@type"]).to eq "dctypes:Image"
    expect(first_canvas.images.first["resource"]["width"]).to eq 2591
  end

  it "has an image resource with a service" do
    expect(first_canvas.images.first["resource"]["service"]["@id"]).to eq "http://iiif_image:8182/iiif/2/1053442"
    expect(third_to_last_canvas.images.first["resource"]["service"]["@id"]).to eq "http://iiif_image:8182/iiif/2/1053448"
    expect(first_canvas.images.first["resource"]["service"]["@context"]).to eq "http://iiif.io/api/image/2/context.json"
  end

  it "can output a manifest as json" do
    expect(manifest_factory.manifest.to_json(pretty: true)).to include "Islamic prayers, invocations and decorations : manuscript."
  end

  it "can save a manifest to S3" do
    allow(Rails.logger).to receive(:info) { :logger_mock }
    manifest_factory.save_manifest
    expect(Rails.logger).to have_received(:info)
      .with("IIIF Manifest Saved: {\"oid\":\"#{oid}\"}")
  end
end
