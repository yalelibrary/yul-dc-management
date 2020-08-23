# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifManifestFactory, prep_metadata_sources: true do
  around do |example|
    original_manifests_base_url = ENV['IIIF_MANIFESTS_BASE_URL']
    original_image_base_url = ENV["IIIF_IMAGE_BASE_URL"]
    ENV['IIIF_MANIFESTS_BASE_URL'] = "http://localhost/manifests"
    ENV['IIIF_IMAGE_BASE_URL'] = "http://localhost:8182/iiif"
    ENV["ACCESS_MASTER_MOUNT"] = File.join("spec", "fixtures", "goobi", "metadata")
    perform_enqueued_jobs do
      example.run
    end
    ENV['IIIF_MANIFESTS_BASE_URL'] = original_manifests_base_url
    ENV['IIIF_IMAGE_BASE_URL'] = original_image_base_url
  end
  describe "creating a manifest with a valid mets xml import" do
    let(:oid) { "16172421" }
    let(:manifest_factory) { IiifManifestFactory.new(oid) }
    let(:logger_mock) { instance_double("Rails.logger").as_null_object }
    let(:parent_object) { FactoryBot.create(:parent_object, oid: oid) }
    let(:first_canvas) { manifest_factory.manifest.sequences.first.canvases.first }
    let(:third_to_last_canvas) { manifest_factory.manifest.sequences.first.canvases.third_to_last }
    before do
      stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/16172421.json")
        .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "16172421.json")).read)
      stub_request(:put, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/16172421.json")
        .to_return(status: 200)
      stub_metadata_cloud("16172421")
      stub_info
      parent_object
    end

    def stub_info
      file_id_array = ["16188699", "16188700", "16188701", "16188702"]
      file_id_array.map do |file_id|
        stub_request(:get, "#{ENV['IIIF_IMAGE_BASE_URL']}/2/#{file_id}/info.json")
          .to_return(status: 200, body: File.open(File.join(fixture_path, file_id, "info.json")))
      end
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
      expect(manifest_factory.manifest["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/16172421.json"
    end

    it "has a label with the title of the ParentObject" do
      expect(manifest_factory.manifest["label"]).to eq "Strawberry Thief fabric, made by Morris and Company "
    end

    it "can save a manifest to S3" do
      allow(Rails.logger).to receive(:info) { :logger_mock }
      manifest_factory.save_manifest
      expect(Rails.logger).to have_received(:info)
        .with("IIIF Manifest Saved: {\"oid\":\"#{oid}\"}")
    end

    it "can download a manifest from S3" do
      fetch_manifest = JSON.parse(manifest_factory.fetch_manifest)
      expect(fetch_manifest["label"]).to eq "Strawberry Thief fabric, made by Morris and Company "
    end

    it "has a manifest with one or more sequences" do
      expect(manifest_factory.manifest.sequences.class).to eq Array
    end

    it "has a sequence with an id" do
      expect(manifest_factory.manifest.sequences.first["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/sequence/16172421"
    end

    it "creates a canvas for each file" do
      canvas_count = manifest_factory.manifest.sequences.first.canvases.count
      expect(canvas_count).to eq 4
    end

    it "has canvases with ids and labels" do
      expect(first_canvas["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699"
      expect(third_to_last_canvas["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188700"
      expect(first_canvas["label"]).to eq "Swatch 1"
      expect(third_to_last_canvas["label"]).to eq "swatch 2"
    end

    it "has a canvas with width and height" do
      expect(first_canvas["height"]).to eq 4056
      expect(first_canvas["width"]).to eq 2591
    end

    it "has canvases with images" do
      expect(first_canvas.images).to be_instance_of Array
      expect(first_canvas.images.count).to eq 1
      expect(first_canvas.images.first["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699/image/1"
      expect(first_canvas.images.first["@type"]).to eq "oa:Annotation"
      expect(first_canvas.images.first["motivation"]).to eq "sc:painting"
      expect(first_canvas.images.first["on"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699"
      expect(third_to_last_canvas.images.first["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188700/image/1"
      expect(third_to_last_canvas.images.first["@type"]).to eq "oa:Annotation"
      expect(third_to_last_canvas.images.first["motivation"]).to eq "sc:painting"
      expect(third_to_last_canvas.images.first["on"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188700"
    end

    it "has an image with a resource" do
      expect(first_canvas.images.first["resource"]["@id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/16188699/full/!200,200/0/default.jpg"
      expect(third_to_last_canvas.images.first["resource"]["@id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/16188700/full/!200,200/0/default.jpg"
      expect(first_canvas.images.first["resource"]["@type"]).to eq "dctypes:Image"
      expect(first_canvas.images.first["resource"]["height"]).to eq 4056
      expect(first_canvas.images.first["resource"]["width"]).to eq 2591
      expect(third_to_last_canvas.images.first["resource"]["height"]).to eq 4056
      expect(third_to_last_canvas.images.first["resource"]["width"]).to eq 2541
    end

    it "has an image resource with a service" do
      expect(first_canvas.images.first["resource"]["service"]["@id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/16188699"
      expect(third_to_last_canvas.images.first["resource"]["service"]["@id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/16188700"
      expect(first_canvas.images.first["resource"]["service"]["@context"]).to eq "http://iiif.io/api/image/2/context.json"
    end

    it "can output a manifest as json" do
      expect(manifest_factory.manifest.to_json(pretty: true)).to include "Strawberry Thief fabric, made by Morris and Company "
    end
  end
end
