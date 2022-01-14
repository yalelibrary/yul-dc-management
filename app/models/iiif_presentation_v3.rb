# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class IiifPresentationV3
  attr_reader :parent_object, :mets_doc, :oid, :errors

  def image_base_url
    @image_base_url ||= (ENV["IIIF_IMAGE_BASE_URL"] || "http://localhost:8182/iiif")
  end

  def manifest_base_url
    @manifest_base_url ||= (ENV["IIIF_MANIFESTS_BASE_URL"] || "http://localhost/manifests")
  end

  def pdf_base_url
    @pdf_base_url ||= (ENV["PDF_BASE_URL"] || "http://localhost/pdfs")
  end

  def image_service_url(oid)
    "#{image_base_url}/2/#{oid}"
  end

  def image_url(oid)
    "#{image_service_url(oid)}/full/!200,200/0/default.jpg"
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
  # rubocop:disable Metrics/AbcSize
  def manifest
    return @manifest if @manifest
    @manifest = {}
    @manifest["@context"] = ["http://iiif.io/api/search/1/context.json", "http://iiif.io/api/presentation/3/context.json"]
    @manifest['id'] = File.join((ENV['IIIF_MANIFESTS_BASE_URL']).to_s, oid.to_s)
    @manifest['type'] = "Manifest"
    manifest_descriptive_properties
    @manifest['provider'] = [provider]
    @manifest["viewingDirection"] = [@parent_object.viewing_direction] unless @parent_object.viewing_direction.nil? || @parent_object.viewing_direction.empty?
    @manifest["behavior"] = [@parent_object.display_layout] unless @parent_object.display_layout.nil? || @parent_object.display_layout.empty?
    @manifest["items"] = []
    add_canvases_to_manifest(@manifest['items'])
    if parent_object.full_text?
      @manifest["service"] ||= []
      @manifest["service"] << search_service
    end
    @manifest
  end
  # rubocop:enable Metrics/AbcSize

  def manifest_descriptive_properties
    @manifest['label'] = {
      "none" => [@parent_object&.authoritative_json&.[]("title")&.first || '']
    }
    @manifest["homepage"] = homepage
    @manifest["requiredStatement"] = required_statement
    @manifest["rendering"] = rendering
    @manifest["seeAlso"] = see_also
    @manifest["metadata"] = metadata
  end

  def required_statement
    {
      "label" => { "en" => ["Provider"] },
      "value" => { "en" => ["Yale University Library"] }
    }
  end

  def search_service
    base = ENV['BLACKLIGHT_BASE_URL'] || 'http://localhost:3000'
    {
      "@id": File.join(base, "catalog/#{oid}/iiif_search"),
      "@type": "SearchService1",
      "profile": "http://iiif.io/api/search/1/search",
      "service": {
        "@id": File.join(base, "catalog/#{oid}/iiif_suggest"),
        "@type": "AutoCompleteService1",
        "profile": "http://iiif.io/api/search/1/autocomplete"
      }
    }
  end

  def metadata
    values = []
    METADATA_FIELDS.each do |field, hash|
      value = if hash[:digital_only] == true
                @parent_object.send(field.to_s)
              else
                @parent_object&.authoritative_json&.[](field.to_s)
              end
      if value.is_a?(Array)
        value = process_metadata_array value, hash
      else
        unless value.nil?
          value = value.to_s
          value = metadata_url(value, hash) if hash[:is_url]
        end
      end

      values << metadata_pair(hash[:label], value) if value
    end
    values
  end

  def metadata_url(url, hash)
    return unless url
    url = hash[:prefix] + url if hash[:prefix]
    return url unless url.start_with?('http')
    "<span><a href=\"#{url}\">#{url}</a></span>"
  end

  def process_metadata_array(value, hash)
    value = value.reverse if hash[:reverse_array]
    value = value.compact.map { |url| metadata_url(url, hash) } if hash[:is_url]
    value = value.join(hash[:join_char]) if hash[:join_char].present?

    value
  end

  def metadata_pair(label, value)
    value = [value] if value.is_a? String
    { 'label' => { 'en' => [label] }, 'value' => { 'none' => value } }
  end

  def provider
    {
      "id" => "https://www.wikidata.org/wiki/Q2583293",
      "type" => "Agent",
      "label" => { "en" => ["Yale Library"] },
      "homepage" => [
        {
          "id" => "https://library.yale.edu/",
          "type" => "Text",
          "label" => { "en" => ["Yale Library homepage"] },
          "format" => "text/html"
        }
      ]
    }
  end

  def homepage
    [
      {
        "id" => "https://collections.library.yale.edu/catalog/#{@oid}",
        "type" => "Text",
        "format" => "text/html",
        "label" => { "en" => ["Yale Digital Collections page"] }
      }
    ]
  end

  def rendering
    [
      {
        "id" => File.join(pdf_base_url.to_s, "#{@oid}.pdf"),
        "type" => "Text",
        "format" => "application/pdf",
        "label" => { "en" => ["Download as PDF"] }
      }
    ]
  end

  def see_also
    [
      {
        "id" => "https://collections.library.yale.edu/catalog/oai?verb=GetRecord&metadataPrefix=oai_mods&identifier=oai:collections.library.yale.edu:#{oid}",
        "type" => "Dataset",
        "format" => "application/mods+xml",
        "profile" => "http://www.loc.gov/mods/v3"
      }
    ]
  end

  def image_resource(child)
    {
      'id' => image_url(child.oid),
      'type' => "Image",
      'format' => "image/jpeg",
      'height' => child.height,
      'width' => child.width,
      'service' => [{
        '@id' => image_service_url(child.oid),
        'type' => 'ImageService2',
        'profile' => 'http://iiif.io/api/image/2/level2.json'
      }]
    }
  end

  def add_image_to_canvas(child, canvas)
    annotation_page = {
      "id" => File.join(manifest_base_url.to_s, "oid/#{oid}/canvas/#{child.oid}/page/1"),
      "type" => "AnnotationPage",
      "items" => []
    }
    canvas["items"] << annotation_page
    image = {}
    image['id'] = File.join(manifest_base_url.to_s, "oid/#{oid}/canvas/#{child.oid}/image/1")
    image['type'] = "Annotation"
    image["motivation"] = "painting"
    image["target"] = File.join(manifest_base_url.to_s, "oid/#{oid}/canvas/#{child.oid}")
    image["body"] = image_resource(child)
    annotation_page["items"] << image
    canvas['thumbnail'] = [image_resource(child)]
    @manifest['thumbnail'] = [image_resource(child)] if child_is_thumbnail?(child[:oid])
  end

  # rubocop:disable Metrics/AbcSize
  def add_canvases_to_manifest(items)
    child_objects = parent_object.child_objects
    child_objects.map do |child, index|
      canvas = {
        "type" => "Canvas",
        "items" => []
      }
      canvas['id'] = File.join(manifest_base_url.to_s, "oid/#{oid}/canvas/#{child.oid}")
      canvas['label'] = { "none" => [child.label || ''] }
      add_image_to_canvas(child, canvas)
      image_anno = canvas["items"].first["items"].first["body"]
      canvas['height'] = image_anno["height"]
      canvas['width'] = image_anno["width"]
      canvas['behavior'] = [child.viewing_hint] unless child.viewing_hint.nil? || child.viewing_hint.empty?
      add_metadata_to_canvas(canvas, child)
      @manifest["start"] = { 'id' => canvas['id'], 'type' => 'Canvas' } if child_is_start_canvas? child.oid, index
      items << canvas
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
# rubocop:enable Metrics/ClassLength
