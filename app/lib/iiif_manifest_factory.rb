# frozen_string_literal: true


class IiifManifestFactory
  attr_reader :oid, :manifest

  require 'iiif/presentation'

  def initialize(oid)
    @oid = oid
    @manifest = construct_manifest
  end

  # Build the actual manifest object
  def construct_manifest
    manifest = IIIF::Presentation::Manifest.new(seed)
    manifest
  end

  def seed
    {
        '@id' => "#{ENV["IIIF_MANIFESTS_BASE_URL"]}#{@oid}.json",
        'label' => 'My Manifest'
    }
  end

  # def self.generate_manifest(oid)
  #   manifest = iiif_manifest.new
  #   seed = {
  #       '@id' => "#{ENV["IIIF_MANIFESTS_BASE_URL"]}#{oid}.json",
  #       'label' => 'My Manifest'
  #   }
  #   # Any options you add are added to the object
  #   manifest = IIIF::Presentation::Manifest.new(seed)
  #   manifest
    #
    # canvas = IIIF::Presentation::Canvas.new()
    # # All classes act like `ActiveSupport::OrderedHash`es, for the most part.
    # # Use `[]=` to set JSON-LD properties...
    # canvas['@id'] = 'http://example.com/canvas'
    # # ...but there are also accessors and mutators for the properties mentioned in
    # # the spec
    # canvas.width = 10
    # canvas.height = 20
    # canvas.label = 'My Canvas'
    #
    # oc = IIIF::Presentation::Resource.new('@id' => 'http://example.com/content')
    # canvas.other_content << oc
    #
    # manifest.sequences << canvas

    # manifest.to_json(pretty: true)
  # end


#   def self.generate_manifest(oid)
#     fest = IiifManifest.new
#     fest.manifest_hash(oid).to_json
#   end
#
#   def fetch_manifest(oid)
#     S3Service.download("manifests/#{oid}.json")
#   end
# #
#   def save_manifest(oid)
#     S3Service.upload("manifests/#{oid}.json", IiifManifest.generate_manifest(oid))
#     iiif_info = { oid: oid }
#     Rails.logger.info("IIIF Manifest Saved: #{iiif_info.to_json}")
#   end
#
#   def manifest_hash(oid)
#     {
#       "@context": "http://iiif.io/api/presentation/2/context.json",
#       "@type": "sc:Manifest",
#       "@id": "#{ENV["IIIF_MANIFESTS_BASE_URL"]}#{oid}.json",
#       "label": "Fair Lucretia’s garland"
#     }
#   end
#
#   def iiif_manifest
#     File.open(File.join("spec", "fixtures", "manifests", "2107188.json")).read
#   end
end
