# frozen_string_literal: true

class IiifPresentation
  attr_reader :parent_object, :mets_doc, :oid, :errors

  require 'iiif/presentation'

  def image_base_url
    @image_base_url ||= (ENV["IIIF_IMAGE_BASE_URL"] || "http://localhost:8182/iiif")
  end

  def manifest_base_url
    @manifest_base_url ||= (ENV["IIIF_MANIFESTS_BASE_URL"] || "http://localhost/manifests")
  end

  def pdf_base_url
    @pdf_base_url ||= (ENV["PDF_BASE_URL"] || "http://localhost/pdfs")
  end

  def image_url(oid)
    "#{image_base_url}/2/#{oid}"
  end

  def initialize(parent_object)
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
    @manifest["rendering"] = rendering
    @manifest["metadata"] = metadata
    @manifest["attribution"] = "Yale University Library"
    @manifest.sequences << sequence
    add_canvases_to_sequence(@manifest.sequences.first)
    @manifest
  end

  def sequence
    return @sequence if @sequence
    @sequence = IIIF::Presentation::Sequence.new
    @sequence["@id"] = "#{ENV['IIIF_MANIFESTS_BASE_URL']}/sequence/#{oid}"
    @sequence["rendering"] = rendering
    @sequence["viewingDirection"] = @parent_object.viewing_direction unless @parent_object.viewing_direction.nil? || @parent_object.viewing_direction.empty?
    @sequence["viewingHint"] = @parent_object.display_layout unless @parent_object.display_layout.nil? || @parent_object.display_layout.empty?
    @sequence
  end

  def metadata
    values = []
    METADATA_FIELDS.each do |m_field|
      value = if m_field[:digital_only] == true
                @parent_object.send(m_field[:field])
              else
                @parent_object&.authoritative_json&.[](m_field[:field])
              end
      value = value.to_s unless value.nil? || value.is_a?(Array)
      values << metadata_pair(m_field[:label], value) if value
    end
    values
  end

  def metadata_pair(label, value)
    value = [value] if value.is_a? String
    { 'label' => label, 'value' => value }
  end

  def rendering
    [
      {
        "@id" => "#{pdf_base_url}/#{@oid}.pdf",
        "format" => "application/pdf",
        "label" => "Download as PDF"
      }
    ]
  end

  def add_image_to_canvas(child, canvas)
    images = canvas.images
    image = IIIF::Presentation::Resource.new
    image['@id'] = "#{manifest_base_url}/oid/#{oid}/canvas/#{child.oid}/image/1"
    image['@type'] = "oa:Annotation"
    image["motivation"] = "sc:painting"
    image["on"] = "#{manifest_base_url}/oid/#{oid}/canvas/#{child.oid}"
    image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
      service_id: image_url(child.oid),
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
      canvas['@id'] = "#{manifest_base_url}/oid/#{oid}/canvas/#{child.oid}"
      canvas['label'] = child.label
      add_image_to_canvas(child, canvas)
      canvas['height'] = canvas.images.first["resource"]["height"]
      canvas['width'] = canvas.images.first["resource"]["width"]
      canvas['viewingHint'] = child.viewing_hint unless child.viewing_hint == ""
      add_metadata_to_canvas(canvas, child)
      canvases << canvas
    end
  end

  def add_metadata_to_canvas(canvas, child)
    metadata_values = []
    metadata_values <<  metadata_pair('Image OID', child.oid.to_s) if child.oid
    metadata_values <<  metadata_pair('Image Label', child.label) if child.label
    metadata_values <<  metadata_pair('Image Caption', child.caption) if child.caption
    canvas['metadata'] = metadata_values
    canvas
  end

  def seed
    {
      '@id' => "#{ENV['IIIF_MANIFESTS_BASE_URL']}/#{@oid}",
      'label' => @parent_object&.authoritative_json&.[]("title")&.first
    }
  end

  def pairtree_path
    Partridge::Pairtree.oid_to_pairtree(oid)
  end

  def fetch
    S3Service.download(manifest_path)
  end

  def save
    upload = S3Service.upload(manifest_path, manifest.to_json(pretty: true))
    upload.successful?
  end

  def manifest_path
    @manifest_path ||= "manifests/#{pairtree_path}/#{oid}.json" if pairtree_path && oid
  end
end
