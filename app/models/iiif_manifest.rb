# frozen_string_literal: true

class IiifManifest
  def fetch_manifest(oid)
    S3Service.download("manifests/#{oid}.json")
  end

  def save_manifest(oid)
    S3Service.upload("manifests/#{oid}.json", iiif_manifest)
    iiif_info = { oid: oid }
    Rails.logger.info("IIIF Manifest Saved: #{iiif_info.to_json}")
  end

  def iiif_manifest
    File.open(File.join("spec", "fixtures", "manifests", "2107188.json")).read
  end
end
