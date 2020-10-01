class BatchProcess < ApplicationRecord
  attr_reader :file
  after_create :refresh_metadata_cloud
  validate :check_file_type
  has_many :users

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
    metadata_sources = parsed_csv.entries.map { |r| r['Source'] }
    MetadataCloudService.create_parent_objects_from_oids(oids, metadata_sources)
  end
end
