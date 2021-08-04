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
    @manifest["related"] = related
    @manifest["rendering"] = rendering
    @manifest["seeAlso"] = see_also
    @manifest["metadata"] = metadata
    @manifest["attribution"] = "Yale University Library"
    @manifest.sequences << sequence
    add_canvases_to_sequence(@manifest.sequences.first)
    if parent_object.full_text?
      @manifest["service"] ||= []
      @manifest["service"] << search_service
    end
    @manifest
  end

  def search_service
    base = ENV['BLACKLIGHT_BASE_URL'] || 'http://localhost:3000'
    {
      "@context": "http://iiif.io/api/search/0/context.json",
      "@id": File.join(base, "catalog/#{oid}/iiif_search"),
      "profile": "http://iiif.io/api/search/0/search",
      "service": {
        "@id": File.join(base, "catalog/#{oid}/iiif_suggest"),
        "profile": "http://iiif.io/api/search/0/autocomplete"
      }
    }
  end

  def sequence
    return @sequence if @sequence
    @sequence = IIIF::Presentation::Sequence.new
    @sequence["@id"] = File.join((ENV['IIIF_MANIFESTS_BASE_URL']).to_s, "sequence/#{oid}")
    @sequence["rendering"] = rendering
    @sequence["viewingDirection"] = @parent_object.viewing_direction unless @parent_object.viewing_direction.nil? || @parent_object.viewing_direction.empty?
    @sequence["viewingHint"] = @parent_object.display_layout unless @parent_object.display_layout.nil? || @parent_object.display_layout.empty?
    @sequence
  end

  def metadata
    values = []
    METADATA_FIELDS.each do |field, hash|
      value = if hash[:digital_only] == true
                @parent_object.send(field.to_s)
              else
                @parent_object&.authoritative_json&.[](field.to_s)
              end
      value = value.to_s unless value.nil? || value.is_a?(Array)
      values << metadata_pair(hash[:label], value) if value
    end
    values
  end

  def metadata_pair(label, value)
    value = [value] if value.is_a? String
    { 'label' => label, 'value' => value }
  end

  def related
    [
      {
        "@id" => "https://collections.library.yale.edu/catalog/#{@oid}",
        "format" => "text/html",
        "label" => "Yale Digital Collections page"
      }
    ]
  end

  def rendering
    [
      {
        "@id" => File.join(pdf_base_url.to_s, "#{@oid}.pdf"),
        "format" => "application/pdf",
        "label" => "Download as PDF"
      }
    ]
  end

  def see_also
    [
      {
        "@id" => "https://collections.library.yale.edu/catalog/oai?verb=GetRecord&metadataPrefix=oai_mods&identifier=oai:collections.library.yale.edu:#{oid}",
        "format" => "application/mods+xml",
        "profile" => "http://www.loc.gov/mods/v3"
      }
    ]
  end

  def add_image_to_canvas(child, canvas)
    images = canvas.images
    image = IIIF::Presentation::Resource.new
    image['@id'] = File.join(manifest_base_url.to_s, "oid/#{oid}/canvas/#{child.oid}/image/1")
    image['@type'] = "oa:Annotation"
    image["motivation"] = "sc:painting"
    image["on"] = File.join(manifest_base_url.to_s, "oid/#{oid}/canvas/#{child.oid}")
    image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
      service_id: image_url(child.oid),
      height: child.height,
      width: child.width,
      profile: 'http://iiif.io/api/image/2/level2.json'
    )
    image["resource"] = image_resource

    @manifest['thumbnail'] = [image_resource] if child_is_thumbnail?(child[:oid])
    images << image
  end

  # rubocop:disable Metrics/AbcSize
  def add_canvases_to_sequence(sequence)
    canvases = sequence.canvases
    child_objects = parent_object.child_objects
    child_objects.map do |child, index|
      canvas = IIIF::Presentation::Canvas.new
      canvas['@id'] = File.join(manifest_base_url.to_s, "oid/#{oid}/canvas/#{child.oid}")
      canvas['label'] = child.label || ''
      add_image_to_canvas(child, canvas)
      canvas['height'] = canvas.images.first["resource"]["height"]
      canvas['width'] = canvas.images.first["resource"]["width"]
      canvas['viewingHint'] = child.viewing_hint unless child.viewing_hint == ""
      add_metadata_to_canvas(canvas, child)

      @manifest["startCanvas"] = canvas['@id'] if child_is_start_canvas? child.oid, index
      canvases << canvas
    end
  end
  # rubocop:enable Metrics/AbcSize

  def add_metadata_to_canvas(canvas, child)
    metadata_values = []
    metadata_values <<  metadata_pair('Image OID', child.oid.to_s) if child.oid
    metadata_values <<  metadata_pair('Image Label', child.label) if child.label
    metadata_values <<  metadata_pair('Image Caption', child.caption) if child.caption
    canvas['metadata'] = metadata_values
    canvas
  end

  def child_is_start_canvas?(child, index)
    return true if index.eql? 0 # set the first child as start canvas
    return false unless child_is_thumbnail? child
    child_oids = @parent_object.child_objects.map { |child_cur| child_cur[:oid] }

    child_oids.index(child) < 10 # only set if the rep. child is one of the first 10
  end

  def child_is_thumbnail?(child)
    @parent_object.representative_child.oid.eql? child # checks if child is the rep
  end

  def seed
    {
      '@id' => File.join((ENV['IIIF_MANIFESTS_BASE_URL']).to_s, oid.to_s),
      'label' => @parent_object&.authoritative_json&.[]("title")&.first
    }
  end

  def pairtree_path
    Partridge::Pairtree.oid_to_pairtree(oid)
  end

  def fetch
    S3Service.download(manifest_path)
  end

  def formatted_manifest
    manifest.to_json(pretty: true)
  end

  def save
    S3Service.upload_if_changed(manifest_path, formatted_manifest)
  end

  def manifest_path
    @manifest_path ||= "manifests/#{pairtree_path}/#{oid}.json" if pairtree_path && oid
  end
end
