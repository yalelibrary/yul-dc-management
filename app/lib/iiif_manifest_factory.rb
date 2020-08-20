# frozen_string_literal: true

class IiifManifestFactory
  attr_reader :oid, :manifest, :parent_object, :mets_doc

  require 'iiif/presentation'

  def initialize(oid)
    @manifest_base_url = ENV["IIIF_MANIFESTS_BASE_URL"] || "http://localhost/manifests/"
    @image_base_url = ENV["IIIF_IMAGE_BASE_URL"] || "http://localhost:8182/iiif"
    @oid = oid
    @parent_object = ParentObject.find_by(oid: oid)
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
    sequence["@id"] = "#{ENV['IIIF_MANIFESTS_BASE_URL']}/sequence/#{oid}"
    sequence
  end

  def add_image_to_canvas(child, canvas)
    images = canvas.images
    image = IIIF::Presentation::Resource.new
    image['@id'] = "#{@manifest_base_url}/oid/#{@oid}/canvas/#{child.child_oid}/image/1"
    image['@type'] = "oa:Annotation"
    image["motivation"] = "sc:painting"
    image["on"] = "#{@manifest_base_url}/oid/#{@oid}/canvas/#{child.child_oid}"

    image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
      service_id: "#{@image_base_url}/2/#{child.child_oid}"
    )
    image["resource"] = image_resource
    images << image
  end

  def add_canvases_to_sequence(sequence)
    canvases = sequence.canvases
    child_objects = ChildObject.where(parent_object: parent_object).order(:order)
    child_objects.map do |child|
      canvas = IIIF::Presentation::Canvas.new
      canvas['@id'] = "#{@manifest_base_url}/oid/#{@oid}/canvas/#{child.child_oid}"
      canvas['label'] = child.label
      add_image_to_canvas(child, canvas)
      canvas['height'] = canvas.images.first["resource"]["height"]
      canvas['width'] = canvas.images.first["resource"]["width"]
      canvases << canvas
    end
  end

  def seed
    {
      '@id' => "#{ENV['IIIF_MANIFESTS_BASE_URL']}/#{@oid}.json",
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
