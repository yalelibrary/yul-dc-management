# frozen_string_literal: true

class IiifPresentation
  attr_reader :parent_object, :mets_doc, :oid, :errors

  require 'iiif/presentation'

  def initialize(parent_object)
    @manifest_base_url = ENV["IIIF_MANIFESTS_BASE_URL"] || "http://localhost/manifests/"
    @image_base_url = ENV["IIIF_IMAGE_BASE_URL"] || "http://localhost:8182/iiif"
    @parent_object = parent_object
    @oid = parent_object.oid
    @errors = ActiveModel::Errors.new(self)
  end

  def valid?
    if ChildObject.where(parent_object: parent_object).order(:order).empty?
      errors.add(:manifest, "There are no child objects for #{@oid}")
      return false
    end
    true
  end

  # Build the actual manifest object
  def manifest
    return @manifest if @manifest
    @manifest = IIIF::Presentation::Manifest.new(seed)
    @manifest.sequences << sequence
    add_canvases_to_sequence(@manifest.sequences.first)
    @manifest
  end

  def sequence
    return @sequence if @sequence
    @sequence = IIIF::Presentation::Sequence.new
    @sequence["@id"] = "#{ENV['IIIF_MANIFESTS_BASE_URL']}/sequence/#{oid}"
    @sequence
  end

  def add_image_to_canvas(child, canvas)
    images = canvas.images
    image = IIIF::Presentation::Resource.new
    image['@id'] = "#{@manifest_base_url}/oid/#{oid}/canvas/#{child.oid}/image/1"
    image['@type'] = "oa:Annotation"
    image["motivation"] = "sc:painting"
    image["on"] = "#{@manifest_base_url}/oid/#{oid}/canvas/#{child.oid}"
    image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
      service_id: "#{@image_base_url}/2/#{child.oid}",
      height: child.height,
      width: child.width,
      profile: 'http://iiif.io/api/image/2/level2.json'
    )
    image["resource"] = image_resource
    images << image
  end

  def add_canvases_to_sequence(sequence)
    canvases = sequence.canvases
    child_objects = ChildObject.where(parent_object: parent_object).order(:order)
    child_objects.map do |child|
      canvas = IIIF::Presentation::Canvas.new
      canvas['@id'] = "#{@manifest_base_url}/oid/#{oid}/canvas/#{child.oid}"
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

  def pairtree_path
    Partridge::Pairtree.oid_to_pairtree(oid)
  end

  def fetch
    S3Service.download("manifests/#{pairtree_path}/#{oid}.json")
  end

  def save
    S3Service.upload("manifests/#{pairtree_path}/#{oid}.json", manifest.to_json(pretty: true))
    iiif_info = { oid: oid }
    Rails.logger.info("IIIF Manifest Saved: #{iiif_info.to_json}")
  end
end
