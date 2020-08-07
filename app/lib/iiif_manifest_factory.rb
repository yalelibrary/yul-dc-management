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
    manifest.sequences = construct_sequences
    manifest.sequences << construct_canvases
    manifest
  end

  def construct_sequences
    sequences = []
    sequence = IIIF::Presentation::Sequence.new
    sequence["@id"] = "http://127.0.0.1/manifests/sequence/#{@oid}"
    sequences << sequence
    sequences
  end

  def construct_canvases
    canvases = []
    images = @mets_doc.combined
    images.map do |image|
      canvas = IIIF::Presentation::Canvas.new
      canvas['@id'] = "http://127.0.0.1/manifests/oid/#{@oid}/canvas/#{image[:image_id]}"
      canvas['label'] = image[:order_label]
      canvas['width'] = 1
      canvas['height'] = 2
      canvases << canvas
    end
    canvases
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
