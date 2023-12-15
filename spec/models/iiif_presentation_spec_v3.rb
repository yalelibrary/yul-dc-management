# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifPresentationV3, prep_metadata_sources: true, prep_admin_sets: true do
  around do |example|
    original_blacklight_base_url = ENV['BLACKLIGHT_BASE_URL']
    original_manifests_base_url = ENV['IIIF_MANIFESTS_BASE_URL']
    original_image_base_url = ENV["IIIF_IMAGE_BASE_URL"]
    original_pdf_url = ENV["PDF_BASE_URL"]
    original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
    ENV['BLACKLIGHT_BASE_URL'] = "http://localhost:3000"
    ENV['IIIF_MANIFESTS_BASE_URL'] = "http://localhost/manifests"
    ENV['IIIF_IMAGE_BASE_URL'] = "http://localhost:8182/iiif"
    ENV["PDF_BASE_URL"] = "http://localhost/pdfs"
    ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
    perform_enqueued_jobs do
      example.run
    end
    ENV['BLACKLIGHT_BASE_URL'] = original_blacklight_base_url
    ENV['IIIF_MANIFESTS_BASE_URL'] = original_manifests_base_url
    ENV['IIIF_IMAGE_BASE_URL'] = original_image_base_url
    ENV["PDF_BASE_URL"] = original_pdf_url
    ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
  end
  let(:oid) { 16_172_421 }
  let(:aspace_oid) { 123 }
  let(:oid_no_labels) { 2_005_512 }
  let(:logger_mock) { instance_double("Rails.logger").as_null_object }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: oid, viewing_direction: "left-to-right", display_layout: "individuals", bib: "12834515", rights_statement: "This is a test") }
  let(:aspace_parent_object) { FactoryBot.create(:parent_object, oid: aspace_oid, bib: "12834515", aspace_uri: "/repositories/11/archival_objects/214638") }
  let(:aspace_iiif_presentation) { described_class.new(aspace_parent_object) }
  let(:iiif_presentation) { described_class.new(parent_object) }
  let(:iiif_presentation_no_labels) { described_class.new(parent_object_no_labels) }
  let(:parent_object_no_labels) { FactoryBot.create(:parent_object, oid: oid_no_labels, viewing_direction: "left-to-right", display_layout: "individuals", bib: "16173726") }
  let(:first_canvas) { iiif_presentation.manifest['items'].first }
  let(:third_to_last_canvas) { iiif_presentation.manifest['items'].third_to_last }
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
    allow(aspace_parent_object).to receive(:authoritative_json).and_return(JSON.parse(File.read(File.join(fixture_path, "aspace", "AS-2005512.json"))))
  end

  describe 'building a manifest' do
    it "does have the search service section if the parent_object full_text? is true" do
      allow(parent_object_no_labels).to receive(:full_text?).and_return true
      expect(iiif_presentation_no_labels.manifest["service"].first[:@id]).to eq("http://localhost:3000/catalog/2005512/iiif_search")
      expect(iiif_presentation_no_labels.manifest["service"].first[:@type]).to eq("SearchService1")
      expect(iiif_presentation_no_labels.manifest["service"].first[:profile]).to eq("http://iiif.io/api/search/1/search")
      expect(iiif_presentation_no_labels.manifest["service"].first[:service][:@id]).to eq("http://localhost:3000/catalog/2005512/iiif_suggest")
      expect(iiif_presentation_no_labels.manifest["service"].first[:service][:@type]).to eq("AutoCompleteService1")
      expect(iiif_presentation_no_labels.manifest["service"].first[:service][:profile]).to eq("http://iiif.io/api/search/1/autocomplete")
    end

    it "does NOT have the service section if the parent_object full_text? is false" do
      expect(iiif_presentation.manifest["service"]).to eq(nil)
    end
  end

  describe "creating a manifest with a valid mets xml import" do
    it "can be instantiated" do
      expect(iiif_presentation.oid).to eq oid
    end

    it "has a parent object" do
      expect(iiif_presentation.parent_object.class).to eq ParentObject
    end

    it "has the IIIF Presentation API v3 context and type of Manifest" do
      expect(iiif_presentation.manifest['@context'].last).to eq "http://iiif.io/api/presentation/3/context.json"
      expect(iiif_presentation.manifest['type']).to eq "Manifest"
    end

    # see also https://github.com/yalelibrary/yul-dc-iiif-manifest/blob/3f96a09d9d5a7b6a49c051d663b5cc2aa5fd8475/templates/webapp.conf.template#L56
    it "generates the manifest id using the environment variable IIIF_MANIFESTS_BASE_URL" do
      expect(iiif_presentation.manifest["id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/16172421"
    end

    it "has a label with the title of the ParentObject" do
      expect(iiif_presentation.manifest["label"]["none"]).to eq ["Strawberry Thief fabric, made by Morris and Company "]
    end

    it "includes all creators" do
      creators = aspace_iiif_presentation.manifest["metadata"].find { |v| v["label"]["en"] == ["Creator"] }["value"]["none"]
      expect(creators.length).to eq(2)
      expect(creators.find { |c| c == "<span><i>From the Collection:</i> The Parent Creator</span>" })
    end

    it "includes related resources online" do
      related_resources = iiif_presentation.manifest["metadata"].find { |v| v["label"]["en"] == ["Related Resources Online"] }["value"]["none"]
      expect(related_resources.length).to eq(2)
      expect(related_resources.find { |r| r == "<span><a href=\"https://pre1600ms.beinecke.library.yale.edu/docs/pre1600.ms314.htm\">View a detailed description.</a></span>" })
    end

    it "has a requiredStatement" do
      expect(iiif_presentation.manifest["requiredStatement"].class).to eq Hash
      expect(iiif_presentation.manifest["requiredStatement"]["label"]["en"].first).to eq "Provider"
      expect(iiif_presentation.manifest["requiredStatement"]["value"]["en"].first).to eq "Yale University Library"
    end

    it "can save a manifest to S3" do
      expect(iiif_presentation.save).to eq(true)
    end

    # it "can download a manifest from S3" do
    #   fetch_manifest = JSON.parse(iiif_presentation.fetch)
    #   expect(fetch_manifest["label"]).to eq "Strawberry Thief fabric, made by Morris and Company "
    # end

    it "has a manifest with items array" do
      expect(iiif_presentation.manifest['items'].class).to eq Array
    end

    it "has a homepage in the manifest" do
      expect(iiif_presentation.manifest["homepage"].class).to eq Array
      expect(iiif_presentation.manifest["homepage"].first.class).to eq Hash
      expect(iiif_presentation.manifest["homepage"].first["id"]).to eq "https://collections.library.yale.edu/catalog/#{oid}"
      expect(iiif_presentation.manifest["homepage"].first["type"]).to eq "Text"
      expect(iiif_presentation.manifest["homepage"].first["format"]).to eq "text/html"
      expect(iiif_presentation.manifest["homepage"].first["label"]["en"].first).to eq "Yale Digital Collections page"
    end

    it "has a provider with a label and homepage in the manifest" do
      provider = iiif_presentation.manifest["provider"].first
      expect(provider.class).to eq Hash
      expect(provider["label"].class).to eq Hash
      expect(provider["label"]["en"].class).to eq Array
      expect(provider["label"]["en"].first.class).to eq String
      expect(provider["id"].class).to eq String
      expect(provider["type"]).to eq "Agent"
      expect(provider["homepage"].first["id"]).to eq "https://library.yale.edu/"
      expect(provider["homepage"].first["type"]).to eq "Text"
      expect(provider["homepage"].first["format"]).to eq "text/html"
      expect(provider["homepage"].first["label"].class).to eq Hash
      expect(provider["homepage"].first["label"]["en"].class).to eq Array
      expect(provider["homepage"].first["label"]["en"].first.class).to eq String
    end

    it "has a rendering in the manifest" do
      expect(iiif_presentation.manifest["rendering"].class).to eq Array
      expect(iiif_presentation.manifest["rendering"].first.class).to eq Hash
      expect(iiif_presentation.manifest["rendering"].first["id"]).to eq "#{ENV['PDF_BASE_URL']}/#{oid}.pdf"
      expect(iiif_presentation.manifest["rendering"].first["type"]).to eq "Text"
      expect(iiif_presentation.manifest["rendering"].first["format"]).to eq "application/pdf"
      expect(iiif_presentation.manifest["rendering"].first["label"]['en'].first).to eq "Download as PDF"
    end

    it "has a seeAlso in the manifest" do
      expect(iiif_presentation.manifest["seeAlso"].class).to eq Array
      expect(iiif_presentation.manifest["seeAlso"].first.class).to eq Hash
      # rubocop:disable Layout/LineLength
      expect(iiif_presentation.manifest["seeAlso"].first["id"]).to eq "https://collections.library.yale.edu/catalog/oai?verb=GetRecord&metadataPrefix=oai_mods&identifier=oai:collections.library.yale.edu:#{oid}"
      # rubocop:enable Layout/LineLength
      expect(iiif_presentation.manifest["seeAlso"].first["type"]).to eq "Dataset"
      expect(iiif_presentation.manifest["seeAlso"].first["format"]).to eq "application/mods+xml"
      expect(iiif_presentation.manifest["seeAlso"].first["profile"]).to eq "http://www.loc.gov/mods/v3"
    end

    it "has metadata in the manifest" do
      expect(iiif_presentation.manifest["metadata"].class).to eq Array
      expect(iiif_presentation.manifest["metadata"].first.class).to eq Hash
      expect(iiif_presentation.manifest["metadata"].first["label"]["en"].first).to eq "Creator"
      expect(iiif_presentation.manifest["metadata"].first["value"]['none'].first).to include "Morris &amp; Co. (London, England)"
      expect(iiif_presentation.manifest["metadata"].last.class).to eq Hash
      expect(iiif_presentation.manifest["metadata"].last["label"]['en'].first).to eq "Object ID (OID)"
      expect(iiif_presentation.manifest["metadata"].select { |k| true if k["label"]["en"].first == "Orbis ID" }).not_to be_empty
      expect(iiif_presentation.manifest["metadata"].select { |k| true if k["label"]["en"].first == "Container / Volume Information" }).not_to be_empty
    end

    it "uses database field for right statement in the manifest" do
      expect(iiif_presentation.manifest["metadata"].select { |k| true if k["label"]["en"].first == "Rights" }).not_to be_empty
      expect(iiif_presentation.manifest["metadata"].find { |k| true if k["label"]["en"].first == "Rights" }["value"]["none"]&.first).to eq("This is a test")
    end

    it "has coordinates in metadata" do
      expect(iiif_presentation.manifest["metadata"].find { |v| v["label"]["en"] == ["Coordinates"] }["value"]["none"]).to eq(["(N90 E90 S90 W90)"])
    end

    it "has a ASpace record link in metadata if ASpace record" do
      expect(aspace_iiif_presentation.manifest["metadata"].class).to eq Array
      expect(aspace_iiif_presentation.manifest["metadata"].select { |k| true if k["label"]["en"].first == "Archives at Yale Item Page" }).not_to be_empty
      values = aspace_iiif_presentation.manifest["metadata"].find { |k| true if k["label"]["en"].first == "Archives at Yale Item Page" }["value"]
      expect(values).not_to be_empty
      expect(values['none'].first).to include('href="https://archives.yale.edu')
    end

    it "has a Finding Aid link in metadata if ASpace record" do
      expect(aspace_iiif_presentation.manifest["metadata"].class).to eq Array
      expect(aspace_iiif_presentation.manifest["metadata"].select { |k| true if k["label"]["en"].first == "Finding Aid" }).not_to be_empty
      values = aspace_iiif_presentation.manifest["metadata"].find { |k| true if k["label"]["en"].first == "Finding Aid" }["value"]
      expect(values).not_to be_empty
      expect(values['none'].first).to include('href="http://hdl.handle.net')
    end

    it "does not have a ASpace record link in metadata if Ladybird record" do
      expect(iiif_presentation.manifest["metadata"].class).to eq Array
      expect(iiif_presentation.manifest["metadata"].select { |k| true if k["label"]["en"].first == "Archives at Yale Item Page" }).to be_empty
    end

    it "includes viewingDirection on the manifest when included on parent_object" do
      expect(iiif_presentation.manifest["viewingDirection"].class).to eq String
      expect(iiif_presentation.manifest["viewingDirection"]).to eq "left-to-right"
    end

    it "includes behavior on the manifest when included on parent_object" do
      expect(iiif_presentation.manifest["behavior"].class).to eq Array
      expect(iiif_presentation.manifest["behavior"].first).to eq "individuals"
    end

    it "includes behavior on the canvas when included on the child_object" do
      co = ChildObject.find(16_188_699)
      co.update(viewing_hint: "non-paged")
      expect(first_canvas["behavior"].first).to eq "non-paged"
    end

    it "doesn't include behavior on the canvas when it isn't on the child_object" do
      co = ChildObject.find(16_188_699)
      co.update(viewing_hint: "")
      expect(first_canvas["behavior"]).not_to be
    end

    it "creates a canvas for each file" do
      canvas_count = iiif_presentation.manifest['items'].count
      expect(canvas_count).to eq 4
    end

    it "has canvases with ids and labels" do
      expect(first_canvas["id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699"
      expect(first_canvas["metadata"]).not_to be_nil
      expect(first_canvas["metadata"]).to include("label" => { "en" => ["Image ID"] }, "value" => { "none" => ["16188699"] })
      expect(first_canvas["metadata"]).to include("label" => { "en" => ["Image Label"] }, "value" => { "none" => ["Swatch 1"] })
      expect(third_to_last_canvas["id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188700"
      expect(first_canvas["label"]["none"]).to eq ["Swatch 1"]
      expect(third_to_last_canvas["label"]["none"]).to eq ["swatch 2"]
    end

    it "has canvases with JPEG rendering property" do
      expect(first_canvas["rendering"].first["id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/16188699/full/full/0/default.jpg"
      expect(first_canvas["rendering"].first["label"]["en"].first).to eq "Full size"
      expect(first_canvas["rendering"].first["type"]).to eq "Image"
      expect(first_canvas["rendering"].first["format"]).to eq "image/jpeg"
    end

    it "has canvases with TIFF rendering property" do
      expect(first_canvas["rendering"].length).to eq 2
      tiff_rendering = first_canvas["rendering"][1]
      expect(tiff_rendering["id"]).to eq "#{ENV['BLACKLIGHT_BASE_URL']}/download/tiff/16188699"
      expect(tiff_rendering["label"]["en"].first).to eq "Full size original"
      expect(tiff_rendering["type"]).to eq "Image"
      expect(tiff_rendering["format"]).to eq "image/tiff"
    end

    it "has canvases with ids and labels based on order property of child_objects" do
      co = ChildObject.find(16_188_699)
      co.update(order: 2)
      co = ChildObject.find(16_188_700)
      co.update(order: 1)
      expect(first_canvas["id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188700"
      expect(third_to_last_canvas["label"]["none"]).to eq ["Swatch 1"]
      expect(first_canvas["label"]["none"]).to eq ["swatch 2"]
      expect(third_to_last_canvas["id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699"
      expect(third_to_last_canvas["metadata"]).not_to be_nil
      expect(third_to_last_canvas["metadata"]).to include("label" => { "en" => ["Image ID"] }, "value" => { "none" => ["16188699"] })
      expect(third_to_last_canvas["metadata"]).to include("label" => { "en" => ["Image Label"] }, "value" => { "none" => ["Swatch 1"] })
    end

    it "has canvases with ids and labels based on order property of child_objects, using oid as tie breaker" do
      co = ChildObject.find(16_188_699)
      co.update(order: 1)
      co = ChildObject.find(16_188_700)
      co.update(order: 1)
      expect(first_canvas["id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699"
      expect(third_to_last_canvas["id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188700"
      expect(first_canvas["label"]["none"]).to eq ["Swatch 1"]
      expect(third_to_last_canvas["label"]["none"]).to eq ["swatch 2"]
    end

    it "has a canvas with width and height" do
      expect(first_canvas["height"]).to eq 4056
      expect(first_canvas["width"]).to eq 2591
    end

    it "has canvases with images" do
      annotation_pages = first_canvas["items"]
      expect(annotation_pages).to be_instance_of Array
      expect(annotation_pages.count).to eq 1
      annotations = annotation_pages.first["items"]
      expect(annotations).to be_instance_of Array
      expect(annotations.count).to eq 1
      annotation = annotations.first
      expect(annotation["id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699/image/1"
      expect(annotation["type"]).to eq "Annotation"
      expect(annotation["motivation"]).to eq "painting"
      expect(annotation["target"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188699"

      annotation_pages = third_to_last_canvas["items"]
      expect(annotation_pages).to be_instance_of Array
      expect(annotation_pages.count).to eq 1
      annotations = annotation_pages.first["items"]
      expect(annotations).to be_instance_of Array
      expect(annotations.count).to eq 1
      annotation = annotations.first
      expect(annotation["id"]).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188700/image/1"
      expect(annotation["type"]).to eq "Annotation"
      expect(annotation["motivation"]).to eq "painting"
      expect(annotation['target']).to eq "#{ENV['IIIF_MANIFESTS_BASE_URL']}/oid/16172421/canvas/16188700"
    end

    it "has an image with a resource" do
      annotation = first_canvas["items"].first["items"].first
      image = annotation['body']
      expect(image["id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/16188699/full/full/0/default.jpg"
      expect(image["type"]).to eq "Image"
      expect(image["height"]).to eq 4056
      expect(image["width"]).to eq 2591
    end

    it "has an image resource with a service" do
      annotation = first_canvas["items"].first["items"].first
      image = annotation['body']
      service = image['service'].first
      expect(service["@id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/16188699"
      expect(service['@type']).to eq "ImageService2"
      expect(service['profile']).to eq "http://iiif.io/api/image/2/level2.json"
    end

    it "can output a manifest as json" do
      expect(iiif_presentation.manifest.to_json(pretty: true)).to include "Strawberry Thief fabric, made by Morris and Company "
    end

    it "provides labels for all canvases" do
      iiif_presentation_no_labels.manifest['items'].each do |canvas|
        expect(canvas['label']).not_to be_nil
      end
      expect(iiif_presentation_no_labels.manifest.to_json(pretty: true)).to include '"label":{"none":[""'
    end

    it "wraps values with HTML with spans" do
      parent_object.extent_of_digitization = 'This is <img src="image" />a <a href="test">Test</a>.'
      expect(iiif_presentation.manifest["metadata"].find { |v| v["label"]["en"] == ["Extent of Digitization"] }["value"]["none"]).to eq(['<span>This is a <a href="test">Test</a>.</span>'])
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
      thumb = iiif_presentation_rep.manifest["thumbnail"]
      expect(thumb[0]["id"]).to include parent_object_rep.representative_child.oid.to_s
      expect(thumb[0]["id"]).to include "!300,300"
      scaled_width = (2591.0 * 300 / 4056.0).round
      expect(thumb[0]['width']).to eq scaled_width
      expect(thumb[0]['service']).not_to be_nil
    end

    context 'representative child is one of the first 10 children' do
      it 'sets startCanvas to representative child' do
        parent_object_rep_edited = parent_object_rep
        parent_object_rep_edited.representative_child_oid = parent_object_rep.child_objects[8].oid
        iiif_presentation_rep = described_class.new(parent_object_rep_edited)
        expect(iiif_presentation_rep.manifest["start"]["id"]).to include parent_object_rep_edited.representative_child_oid.to_s
      end
    end

    context 'representative child is not one of the first 10 children' do
      it 'uses the first child as the startCanvas' do
        parent_object_rep_edited = parent_object_rep
        parent_object_rep_edited.representative_child_oid = parent_object_rep.child_objects[20].oid

        iiif_presentation_rep = described_class.new(parent_object_rep_edited)
        expect(iiif_presentation_rep.manifest["start"]).to be_nil
      end
    end
  end

  describe 'IIIF navPlace ' do
    let(:oid_geojson) { 15_234_629 }
    let(:parent_object_geojson) { FactoryBot.create(:parent_object, oid: oid_geojson, viewing_direction: "left-to-right", display_layout: "individuals", bib: "12834515") }

    before do
      stub_metadata_cloud(15_234_629)
      stub_ptiffs
      stub_pdfs
      parent_object_geojson
      allow(parent_object_geojson).to receive(:authoritative_json).and_return(JSON.parse(File.read(File.join(fixture_path, "ils", "V-#{oid_geojson}.json"))))
    end

    it 'is produced when an ILS item has coordinates' do
      iiif_presentation_geojson = described_class.new(parent_object_geojson)
      nav_place = iiif_presentation_geojson.manifest['navPlace']
      expect(nav_place).not_to be_nil
      expect(nav_place['type']).to eq 'FeatureCollection'
      coords = nav_place['features'][0]['geometry']['coordinates']
      expect(coords).to eq([[[180.0, 90.0], [-180.0, 90.0], [-180.0, -90.0], [180.0, -90.0], [180.0, 90.0]]])
    end

    it 'is not produced for an ASpace item' do
      iiif_presentation_no_geojson = described_class.new(aspace_parent_object)
      nav_place = iiif_presentation_no_geojson.manifest['navPlace']
      expect(nav_place).to be_nil
    end
  end

  describe 'IIIF navDate ' do
    let(:single_date_oid) { oid }
    let(:parent_object_single_date) { parent_object }
    let(:split_date_oid) { 16_685_691 }
    let(:parent_object_split_date) { FactoryBot.create(:parent_object, oid: split_date_oid) }
    let(:empty_date_oid) { oid_no_labels }
    let(:parent_object_empty_date) { parent_object_no_labels }

    before do
      stub_metadata_cloud(single_date_oid)
      stub_metadata_cloud(split_date_oid)
      parent_object_single_date
      parent_object_split_date
      parent_object_empty_date
      allow(parent_object_single_date).to receive(:authoritative_json).and_return(JSON.parse(File.read(File.join(fixture_path, "ladybird", "#{single_date_oid}.json"))))
      allow(parent_object_split_date).to receive(:authoritative_json).and_return(JSON.parse(File.read(File.join(fixture_path, "ladybird", "#{split_date_oid}.json"))))
      allow(parent_object_empty_date).to receive(:authoritative_json).and_return(JSON.parse(File.read(File.join(fixture_path, "ladybird", "#{empty_date_oid}.json"))))
    end

    it 'has navDate in the manifest for a single date' do
      iiif_presentation_single_date = described_class.new(parent_object_single_date)
      expect(iiif_presentation_single_date.manifest['navDate']).to eq '1883-01-01T00:00:00Z'
    end

    it 'has navDate in the manifest for a split date' do
      iiif_presentation_split_date = described_class.new(parent_object_split_date)
      expect(iiif_presentation_split_date.manifest['navDate']).to eq '1914-01-01T00:00:00Z'
    end

    it 'does not have navDate when empty date' do
      iiif_presentation_empty_date = described_class.new(parent_object_empty_date)
      expect(iiif_presentation_empty_date.manifest.key?('navDate')).to eq false
    end
  end

  describe "IIIF rendering" do
    it "downscales the JPEG rendering to MAX_PIXELS" do
      iiif_presentation = described_class.new(parent_object)
      oid = 123
      scaled_rendering = iiif_presentation.jpeg_rendering(oid, 100_000, 200_000)
      expect(scaled_rendering["label"]["en"].first).to eq "Reduced size 7071 x 14142"
      expect(scaled_rendering["id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/#{oid}/full/7071,/0/default.jpg"
    end
    it "does not divide by zero" do
      iiif_presentation = described_class.new(parent_object)
      oid = 123
      scaled_rendering = iiif_presentation.jpeg_rendering(oid, 90_345, 2908)
      expect(scaled_rendering["label"]["en"].first).to eq "Reduced size 55738 x 1794"
      expect(scaled_rendering["id"]).to eq "#{ENV['IIIF_IMAGE_BASE_URL']}/2/#{oid}/full/55738,/0/default.jpg"
    end
  end
end
