# frozen_string_literal: true

class IiifManifestFactory
  attr_reader :oid, :manifest, :parent_object

  require 'iiif/presentation'

  def initialize(oid)
    @oid = oid
    @parent_object = ParentObject.find_by(oid: oid)
    @manifest = construct_manifest
  end

  # Build the actual manifest object
  def construct_manifest
    manifest = IIIF::Presentation::Manifest.new(seed)
    manifest
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
