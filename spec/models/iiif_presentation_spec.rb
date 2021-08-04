# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifPresentation, prep_metadata_sources: true do
  around do |example|
    original_manifests_base_url = ENV['IIIF_MANIFESTS_BASE_URL']
    original_image_base_url = ENV["IIIF_IMAGE_BASE_URL"]
    original_pdf_url = ENV["PDF_BASE_URL"]
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['IIIF_MANIFESTS_BASE_URL'] = "http://localhost/manifests"
    ENV['IIIF_IMAGE_BASE_URL'] = "http://localhost:8182/iiif"
    ENV["PDF_BASE_URL"] = "http://localhost/pdfs"
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    perform_enqueued_jobs do
      example.run
    end
    ENV['IIIF_MANIFESTS_BASE_URL'] = original_manifests_base_url
    ENV['IIIF_IMAGE_BASE_URL'] = original_image_base_url
    ENV["PDF_BASE_URL"] = original_pdf_url
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end
  let(:oid) { 16_172_421 }
  let(:oid_no_labels) { 2_005_512 }
  let(:iiif_presentation) { described_class.new(parent_object) }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: oid, viewing_direction: "left-to-right", display_layout: "individuals", bib: "12834515") }
  let(:iiif_presentation_no_labels) { described_class.new(parent_object_no_labels) }
  let(:parent_object_no_labels) { FactoryBot.create(:parent_object, oid: oid_no_labels, viewing_direction: "left-to-right", display_layout: "individuals", bib: "16173726") }
  let(:first_canvas) { iiif_presentation.manifest.sequences.first.canvases.first }
  let(:third_to_last_canvas) { iiif_presentation.manifest.sequences.first.canvases.third_to_last }
  before do
    stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/21/16/17/24/21/16172421.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, "manifests", "16172421.json")).read)
    stub_request(:put, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/manifests/21/16/17/24/21/16172421.json")
      .to_return(status: 200)
    stub_metadata_cloud("16172421")
    stub_metadata_cloud("2005512")
    stub_ptiffs
    stub_pdfs
    parent_object
    # The parent object gets its metadata populated via a background job, and we can't assume that has run,
    # so stub the part of the metadata we need for the iiif_presentation
    allow(parent_object).to receive(:authoritative_json).and_return(JSON.parse(File.read(File.join(fixture_path, "ladybird", "#{oid}.json"))))
  end

  describe 'building a manifest' do
    it "does have the search service section if the parent_object full_text? is true" do
      allow(parent_object_no_labels).to receive(:full_text?).and_return true
      expect(iiif_presentation_no_labels.manifest["service"].first[:@context]).to eq("http://iiif.io/api/search/0/context.json")
      expect(iiif_presentation_no_labels.manifest["service"].first[:@id]).to eq("http://localhost:3000/catalog/2005512/iiif_search")
      expect(iiif_presentation_no_labels.manifest["service"].first[:profile]).to eq("http://iiif.io/api/search/0/search")
      expect(iiif_presentation_no_labels.manifest["service"].first[:service][:@id]).to eq("http://localhost:3000/catalog/2005512/iiif_suggest")
      expect(iiif_presentation_no_labels.manifest["service"].first[:service][:profile]).to eq("http://iiif.io/api/search/0/autocomplete")
    end

    it "does NOT have the service section if the parent_object full_text? is false" do
      expect(iiif_presentation.manifest["service"]).to eq(nil)
    end
  end

  describe "creating a manifest with a valid mets xml import" do
    it "can be instantiated" do
      expect(iiif_presentation.oid).to eq oid
    end

    it "has a seed from which to build the manifest" do
      expect(iiif_presentation.seed).to be_instance_of Hash
    end

    it "has a manifest" do
      expect(iiif_presentation.manifest.class).to eq IIIF::Presentation::Manifest
    end

    it "has a parent object" do
      expect(iiif_presentation.parent_object.class).to eq ParentObject
    end

    # see also https://github.com/yalelibrary/yul-dc-iiif-manifest/blob/3f96a09d9d5a7b6a49c051d663b5cc2aa5fd8475/templates/webapp.conf.template#L56
    it "saves the manifest with the environment variable IIIF_MANIFESTS_BASE_URL" do
      expect(iiif_presentation.manifest["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/16172421"
    end

    it "has a label with the title of the ParentObject" do
      expect(iiif_presentation.manifest["label"]).to eq "Strawberry Thief fabric, made by Morris and Company "
    end

    it "has an attribution to Yale" do
      expect(iiif_presentation.manifest["attribution"]).to eq "Yale University Library"
    end

    it "can save a manifest to S3" do
      expect(iiif_presentation.save).to eq true
    end

    it "can download a manifest from S3" do
      fetch_manifest = JSON.parse(iiif_presentation.fetch)
      expect(fetch_manifest["label"]).to eq "Strawberry Thief fabric, made by Morris and Company "
    end

    it "has a manifest with one or more sequences" do
      expect(iiif_presentation.manifest.sequences.class).to eq Array
    end

    it "has a related in the manifest" do
      expect(iiif_presentation.manifest["related"].class).to eq Array
      expect(iiif_presentation.manifest["related"].first.class).to eq Hash
      expect(iiif_presentation.manifest["related"].first["@id"]).to eq "https://collections.library.yale.edu/catalog/#{oid}"
      expect(iiif_presentation.manifest["related"].first["format"]).to eq "text/html"
      expect(iiif_presentation.manifest["related"].first["label"]).to eq "Yale Digital Collections page"
    end

    it "has a rendering in the manifest" do
      expect(iiif_presentation.manifest["rendering"].class).to eq Array
      expect(iiif_presentation.manifest["rendering"].first.class).to eq Hash
      expect(iiif_presentation.manifest["rendering"].first["@id"]).to eq "#{ENV['PDF_BASE_URL']}/#{oid}.pdf"
      expect(iiif_presentation.manifest["rendering"].first["format"]).to eq "application/pdf"
      expect(iiif_presentation.manifest["rendering"].first["label"]).to eq "Download as PDF"
    end

    it "has a seeAlso in the manifest" do
      expect(iiif_presentation.manifest["seeAlso"].class).to eq Array
      expect(iiif_presentation.manifest["seeAlso"].first.class).to eq Hash
      # rubocop:disable Metrics/LineLength
      expect(iiif_presentation.manifest["seeAlso"].first["@id"]).to eq "https://collections.library.yale.edu/catalog/oai?verb=GetRecord&metadataPrefix=oai_mods&identifier=oai:collections.library.yale.edu:#{oid}"
      # rubocop:enable Metrics/LineLength
      expect(iiif_presentation.manifest["seeAlso"].first["format"]).to eq "application/mods+xml"
      expect(iiif_presentation.manifest["seeAlso"].first["profile"]).to eq "http://www.loc.gov/mods/v3"
    end

    it "has metadata in the manifest" do
      expect(iiif_presentation.manifest["metadata"].class).to eq Array
      expect(iiif_presentation.manifest["metadata"].first.class).to eq Hash
      expect(iiif_presentation.manifest["metadata"].first["label"]).to eq "Creator"
      expect(iiif_presentation.manifest["metadata"].first["value"].first).to include "Morris & Co. (London, England)"
      expect(iiif_presentation.manifest["metadata"].last.class).to eq Hash
      expect(iiif_presentation.manifest["metadata"].last["label"]).to eq "OID"
      expect(iiif_presentation.manifest["metadata"].select { |k| true if k["label"] == "Orbis ID" }).not_to be_empty
      expect(iiif_presentation.manifest["metadata"].select { |k| true if k["label"] == "Container / Volume Information" }.first["value"].first).to eq 'Box 12 | Folder 117'
    end

    it "has a rendering in the sequence" do
      expect(iiif_presentation.manifest.sequences.first["rendering"].class).to eq Array
      expect(iiif_presentation.manifest.sequences.first["rendering"].first.class).to eq Hash
      expect(iiif_presentation.manifest.sequences.first["rendering"].first["@id"]).to eq "#{ENV['PDF_BASE_URL']}/#{oid}.pdf"
      expect(iiif_presentation.manifest.sequences.first["rendering"].first["format"]).to eq "application/pdf"
      expect(iiif_presentation.manifest.sequences.first["rendering"].first["label"]).to eq "Download as PDF"
    end

    it "includes viewingDirection on the sequence when included on parent_object" do
      expect(iiif_presentation.manifest.sequences.first["viewingDirection"].class).to eq String
      expect(iiif_presentation.manifest.sequences.first["viewingDirection"]).to eq "left-to-right"
      expect(iiif_presentation.manifest.sequences.first["viewingHint"]).to eq "individuals"
    end

    it "includes viewingHint on the canvas when included on the child_object" do
      co = ChildObject.find(16_188_699)
      co.update(viewing_hint: "non-paged")
      expect(first_canvas["viewingHint"]).to eq "non-paged"
    end

    it "doesn't include viewingHint on the canvas when it isn't on the child_object" do
      co = ChildObject.find(16_188_699)
      co.update(viewing_hint: "")
      expect(first_canvas["viewingHint"]).not_to be
    end

    it "has a sequence with an id" do
      expect(iiif_presentation.manifest.sequences.first["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/sequence/16172421"
    end

    it "creates a canvas for each file" do
      canvas_count = iiif_presentation.manifest.sequences.first.canvases.count
      expect(canvas_count).to eq 4
    end

    it "has canvases with ids and labels" do
      expect(first_canvas["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699"
      expect(first_canvas["metadata"]).not_to be_nil
      expect(first_canvas["metadata"]).to include("label" => "Image OID", "value" => ["16188699"])
      expect(first_canvas["metadata"]).to include("label" => "Image Label", "value" => ["Swatch 1"])
      expect(third_to_last_canvas["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188700"
      expect(first_canvas["label"]).to eq "Swatch 1"
      expect(third_to_last_canvas["label"]).to eq "swatch 2"
    end

    it "has canvases with ids and labels based on order property of child_objects" do
      co = ChildObject.find(16_188_699)
      co.update(order: 2)
      co = ChildObject.find(16_188_700)
      co.update(order: 1)
      expect(first_canvas["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188700"
      expect(third_to_last_canvas["label"]).to eq "Swatch 1"
      expect(first_canvas["label"]).to eq "swatch 2"
      expect(third_to_last_canvas["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699"
      expect(third_to_last_canvas["metadata"]).not_to be_nil
      expect(third_to_last_canvas["metadata"]).to include("label" => "Image OID", "value" => ["16188699"])
      expect(third_to_last_canvas["metadata"]).to include("label" => "Image Label", "value" => ["Swatch 1"])
    end

    it "has canvases with ids and labels based on order property of child_objects, using oid as tie breaker" do
      co = ChildObject.find(16_188_699)
      co.update(order: 1)
      co = ChildObject.find(16_188_700)
      co.update(order: 1)
      expect(first_canvas["@id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699"
      expect(first_canvas["metadata"]).not_to be_nil
      expect(first_canvas["metadata"]).to include("label" => "Image OID", "value" => ["16188699"])
      expect(first_canvas["metadata"]).to include("label" => "Image Label", "value" => ["Swatch 1"])
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
      expect(third_to_last_canvas.images.first["resource"]["width"]).to eq 2591
    end

    it "has an image resource with a service" do
      expect(first_canvas.images.first["resource"]["service"]["@id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/16188699"
      expect(third_to_last_canvas.images.first["resource"]["service"]["@id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/16188700"
      expect(first_canvas.images.first["resource"]["service"]["@context"]).to eq "http://iiif.io/api/image/2/context.json"
    end

    it "can output a manifest as json" do
      expect(iiif_presentation.manifest.to_json(pretty: true)).to include "Strawberry Thief fabric, made by Morris and Company "
    end

    it "provides labels for all canvases" do
      iiif_presentation_no_labels.manifest.sequences.first.canvases.each do |canvas|
        expect(canvas['label']).not_to be_nil
      end
      expect(iiif_presentation_no_labels.manifest.to_json(pretty: true)).to include '"label": ""'
    end
  end

  describe 'iiif presentation representative children', :vpn_only do
    let(:oid_rep) { 2_055_095 }
    let(:parent_object_rep) { FactoryBot.create(:parent_object, oid: oid_rep, viewing_direction: "left-to-right", display_layout: "individuals", bib: "12834515") }

    before do
      stub_metadata_cloud("20055095")
      stub_ptiffs
      stub_pdfs
      parent_object_rep
      # The parent object gets its metadata populated via a background job, and we can't assume that has run,
      # so stub the part of the metadata we need for the iiif_presentation
      allow(parent_object_rep).to receive(:authoritative_json).and_return(JSON.parse(File.read(File.join(fixture_path, "ladybird", "#{oid}.json"))))
    end

    it 'sets thumbnail to the representative child' do
      iiif_presentation_rep = described_class.new(parent_object_rep)

      expect(iiif_presentation_rep.manifest["thumbnail"][0]["@id"]).to include parent_object_rep.representative_child.oid.to_s
    end

    context 'representative child is one of the first 10 children' do
      it 'sets startCanvas to representative child' do
        parent_object_rep_edited = parent_object_rep
        parent_object_rep_edited.representative_child_oid = parent_object_rep.child_objects[8].oid

        iiif_presentation_rep = described_class.new(parent_object_rep_edited)
        expect(iiif_presentation_rep.manifest["startCanvas"]).to include parent_object_rep_edited.representative_child_oid.to_s
      end
    end
    context 'representative child is not one of the first 10 children' do
      it 'uses the first child as the startCanvas' do
        parent_object_rep_edited = parent_object_rep
        parent_object_rep_edited.representative_child_oid = parent_object_rep.child_objects[20].oid

        iiif_presentation_rep = described_class.new(parent_object_rep_edited)
        expect(iiif_presentation_rep.manifest["startCanvas"]).to be_nil
      end
    end
  end

  describe 'iiif presentation validations' do
    context 'manifests' do
      manifest = IIIF::Presentation::Manifest.new

      it 'raises an exception if the manifest does not have an id' do
        manifest.label = 'Book 1'
        expect { manifest.validate }.to raise_error IIIF::Presentation::MissingRequiredKeyError
      end

      it 'raises an exception if the manifest does not have an label' do
        manifest['id'] = 'http://www.example.org/iiif/book1/manifest'
        expect { manifest.validate }.to raise_error IIIF::Presentation::MissingRequiredKeyError
      end

      it 'raises an exception if the manifest does not have a type' do
        manifest.delete('@type')
        manifest.label = 'Book 1'
        manifest['id'] = 'http://www.example.org/iiif/book1/manifest'
        expect { manifest.validate }.to raise_error IIIF::Presentation::MissingRequiredKeyError
      end
    end

    it 'raises an exception if the sequence is not an array' do
      expect { (iiif_presentation.manifest.sequences = 'quux') }.to raise_error('sequences must be an Array.')
    end

    it 'raises an exception if the canvas dimensions are not present' do
      canvas = IIIF::Presentation::Canvas.new('@id' => 'http://example.com/canvas')
      expect { canvas.to_json }.to raise_error('A(n) width is required for each IIIF::Presentation::Canvas')
      canvas.width = 191
      expect { canvas.to_json }.to raise_error('A(n) height is required for each IIIF::Presentation::Canvas')
    end

    it 'raises an exception if the images service_id is not included' do
      expect { IIIF::Presentation::ImageResource.create_image_api_image_resource }.to raise_error('key not found: :service_id')
    end

    # #TODO: Fix this test. Not currently working as at should since we are stubbing requests
    xit 'raises an exception if the images service_id is not valid' do
      invalid_service_id = "#{ENV['IIIF_IMAGE_BASE_URL']}/2/16188691"
      expect { IIIF::Presentation::ImageResource.create_image_api_image_resource(service_id: invalid_service_id) }.to raise_error
    end

    context 'with no images in the canvas' do
      let(:no_child_oid) { "100001" }
      let(:no_child_parent_object) { FactoryBot.create(:parent_object, oid: no_child_oid) }
      let(:no_child_iiif_presentation) { IiifPresentation.new(no_child_parent_object) }

      before do
        stub_metadata_cloud("100001")
        no_child_parent_object
      end

      it 'raises an exception if the parent object does not have any child objects (images)' do
        no_child_iiif_presentation.valid?
        expect(no_child_iiif_presentation.errors[:manifest]).to include("There are no child objects for #{no_child_oid}")
        expect(no_child_parent_object).to be_valid
      end

      it 'does not raise an exception if the parent object has child objects (images)' do
        iiif_presentation.valid?
        expect(iiif_presentation.errors[:manifest]).not_to include("There are no child objects for #{oid}")
      end
    end
  end
end
