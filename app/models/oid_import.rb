# frozen_string_literal: true

class OidImport < ApplicationRecord
  attr_reader :file
  validate :check_file_type

  def check_file_type
    return if file.blank?
    errors.add(:file, 'must be a csv') if CSV.read(file).blank?
  end

  def file=(value)
    @file = value
    self[:csv] = value.read
  end

  def parsed_csv
    @parsed_csv ||= CSV.parse(csv, headers: true) if csv.present?
  end

  def refresh_metadata_cloud
    oids = parsed_csv.entries.map { |r| r['oid'] }
    MetadataCloudService.create_parent_objects_from_oids(oids, 'ladybird') # TODO: make 'ladybird' a metadata source attribute on this object
  end
end
