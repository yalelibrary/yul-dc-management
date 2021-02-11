# frozen_string_literal: true

module MetadataCloudUrlParsable
  extend ActiveSupport::Concern

  def parsed_metadata_source_path
    @parsed_metadata_source_path ||= metadata_source_path.match(/\/(\w*)\/(\w*)\/(\d*)\W(\w*)\W(\w*)/)
  end

  def full_metadata_cloud_url
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}#{metadata_source_path}"
  end

  def metadata_source
    parsed_metadata_source_path.captures.first
  end

  def bib
    parsed_metadata_source_path.captures.last if metadata_source == "ils"
  end

  def barcode
    parsed_metadata_source_path.captures.third if parsed_metadata_source_path.captures.include?("barcode")
  end

  def holding
    parsed_metadata_source_path.captures.third if parsed_metadata_source_path.captures.include?("holding")
  end

  def item
    parsed_metadata_source_path.captures.third if parsed_metadata_source_path.captures.include?("item")
  end

  # leave of the first "aspace" to match Ladybird archiveSpaceUri. parsed_metadata_source_path.captures
  # is 0-indexed
  def aspace_uri
    return nil unless valid_aspace?
    parsed_path = parsed_metadata_source_path.captures
    File.join("\/", parsed_path[1], parsed_path[2],
              parsed_path[3], parsed_path[4])
  end

  def valid_metadata_source_path?
    return false unless parsed_metadata_source_path
    return false unless valid_ils? || valid_aspace?
    true
  end

  def valid_aspace?
    metadata_source == 'aspace' && (metadata_source_path =~ %r{\A\/aspace\/repositories\/\d+\/archival_objects\/\d+\z})
  end

  def valid_ils?
    metadata_source == 'ils' && (valid_bib? && (valid_item? || valid_holding? || valid_barcode?))
  end

  def valid_barcode?
    barcode && (barcode !~ /\D/)
  end

  def valid_bib?
    bib =~ /\A\d+b?\z/
  end

  def valid_item?
    item && (item !~ /\D/)
  end

  def valid_holding?
    holding && (holding !~ /\D/)
  end
end
