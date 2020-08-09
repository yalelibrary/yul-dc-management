# frozen_string_literal: true

class IiifManifestFactory
  attr_reader :oid, :manifest, :parent_object, :mets_doc

  require 'iiif/presentation'

  def initialize(oid)
    @oid = oid
    @parent_object = ParentObject.find_by(oid: oid)
    goobi_object = GoobiXmlImport.find_by(oid: oid)
    return unless goobi_object
    @mets_doc = MetsDocument.new(goobi_object.goobi_xml)
    @manifest = construct_manifest
  end

  # Build the actual manifest object
  def construct_manifest
    manifest = IIIF::Presentation::Manifest.new(seed)
    manifest.sequences << create_first_sequence(oid)
    add_canvases_to_sequence(manifest.sequences.first)
    manifest
  end

  def create_first_sequence(oid)
    sequence = IIIF::Presentation::Sequence.new
    sequence["@id"] = "http://127.0.0.1/manifests/sequence/#{oid}"
    sequence
  end

  def add_image_to_canvas(file, canvas)
    images = canvas.images
    image = IIIF::Presentation::Resource.new
    image['@id'] = "http://127.0.0.1/manifests/oid/#{@oid}/canvas/#{file[:image_id]}/image/1"
    image['@type'] = "oa:Annotation"
    image["motivation"] = "sc:painting"
    image["on"] = "http://127.0.0.1/manifests/oid/#{@oid}/canvas/#{file[:image_id]}"

    base_url = ENV["IIIF_IMAGE_BASE_URL"]
    image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
      service_id: "#{base_url}/2/#{file[:image_id]}"
    )
    image["resource"] = image_resource
    images << image
  end

  def add_canvases_to_sequence(sequence)
    canvases = sequence.canvases
    image_files = @mets_doc.combined
    image_files.sort_by! { |file| file[:order].to_i }
    image_files.map do |file|
      canvas = IIIF::Presentation::Canvas.new
      canvas['@id'] = "http://127.0.0.1/manifests/oid/#{@oid}/canvas/#{file[:image_id]}"
      canvas['label'] = file[:order_label]
      canvas['height'] = 4075
      canvas['width'] = 2630
      add_image_to_canvas(file, canvas)
      canvases << canvas
    end
  end

  def seed
    {
      '@id' => "http://127.0.0.1/manifests/#{@oid}.json",
      'label' => @parent_object.authoritative_json["title"].first
    }
  end

  def fetch_manifest
    S3Service.download("manifests/#{@oid}.json")
  end

  def save_manifest
    S3Service.upload("manifests/#{oid}.json", @manifest.to_json(pretty: true))
    iiif_info = { oid: @oid }
    Rails.logger.info("IIIF Manifest Saved: #{iiif_info.to_json}")
  end
end
